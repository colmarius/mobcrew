import Foundation
import Combine

protocol MonotonicClockProtocol {
    var now: TimeInterval { get }
}

protocol WallClockProtocol {
    var now: Date { get }
}

struct SystemMonotonicClock: MonotonicClockProtocol {
    private let clock: ContinuousClock
    private let origin: ContinuousClock.Instant

    init() {
        let clock = ContinuousClock()
        self.clock = clock
        self.origin = clock.now
    }

    var now: TimeInterval {
        let components = origin.duration(to: clock.now).components
        return Double(components.seconds) + Double(components.attoseconds) * 1e-18
    }
}

struct SystemWallClock: WallClockProtocol {
    var now: Date {
        Date.now
    }
}

enum TimerRefreshResult: Equatable {
    case inactive
    case active
    case completed
}

enum TimerPauseResult: Equatable {
    case inactive
    case paused
    case completed
}

enum RunningTimerRestoreResult: Equatable {
    case restored
    case expired
    case invalid
}

@MainActor
final class TimerEngine {
    private struct ActiveRun {
        let id: UInt64
        let monotonicDeadline: TimeInterval
        let wallDeadline: Date
    }

    private(set) var state: TimerState
    private let monotonicClock: any MonotonicClockProtocol
    private let wallClock: any WallClockProtocol
    private var frozenRemaining: TimeInterval
    private var activeRun: ActiveRun?
    private var timerCancellable: AnyCancellable?
    private var onComplete: (@MainActor () -> Void)?
    private var generation: UInt64 = 0
    private var lastRunID: UInt64 = 0

    var isRunning: Bool {
        activeRun != nil
    }

    var secondsRemaining: Int {
        state.secondsRemaining
    }

    var runningWallDeadline: Date? {
        activeRun?.wallDeadline
    }

    var frozenExactRemaining: TimeInterval? {
        activeRun == nil ? frozenRemaining : nil
    }

    var isRefreshPublisherArmed: Bool {
        timerCancellable != nil
    }

    init(
        state: TimerState = TimerState(),
        monotonicClock: any MonotonicClockProtocol = SystemMonotonicClock(),
        wallClock: any WallClockProtocol = SystemWallClock()
    ) {
        self.state = state
        self.monotonicClock = monotonicClock
        self.wallClock = wallClock
        self.frozenRemaining = TimeInterval(state.secondsRemaining)
    }

    func configure(onComplete: @escaping @MainActor () -> Void) {
        self.onComplete = onComplete
    }

    func reset(duration: Int) {
        discardActiveRunWithoutRefresh()
        frozenRemaining = TimeInterval(duration)
        state.reset(duration: duration)
    }

    @discardableResult
    func start() -> Bool {
        guard activeRun == nil else { return false }
        guard frozenRemaining > 0, frozenRemaining.isFinite else { return false }

        let wallSample = wallClock.now
        precondition(wallSample.timeIntervalSinceReferenceDate.isFinite)
        let monotonicSample = monotonicClock.now
        precondition(monotonicSample.isFinite)

        let runID = nextRunID()
        activeRun = ActiveRun(
            id: runID,
            monotonicDeadline: monotonicSample + frozenRemaining,
            wallDeadline: wallSample.addingTimeInterval(frozenRemaining)
        )
        _ = armRefreshPublisher()
        return true
    }

    @discardableResult
    func pause() -> TimerPauseResult {
        guard activeRun != nil else { return .inactive }

        switch refresh() {
        case .completed:
            return .completed
        case .active:
            invalidatePublisherAndActiveRun()
            return .paused
        case .inactive:
            return .inactive
        }
    }

    @discardableResult
    func refresh() -> TimerRefreshResult {
        guard let run = activeRun else { return .inactive }
        let monotonicSample = monotonicClock.now
        precondition(monotonicSample.isFinite)
        let remaining = max(0, run.monotonicDeadline - monotonicSample)

        guard remaining > 0 else {
            frozenRemaining = 0
            state.updateRemaining(0)
            invalidatePublisherAndActiveRun(expectedRunID: run.id)
            onComplete?()
            return .completed
        }

        frozenRemaining = remaining
        state.updateRemaining(Int(ceil(remaining)))
        return .active
    }

    func restoreRunning(
        totalSeconds: Int,
        wallDeadline: Date
    ) -> RunningTimerRestoreResult {
        guard activeRun == nil else { return .invalid }
        guard totalSeconds > 0 else { return .invalid }
        guard wallDeadline.timeIntervalSinceReferenceDate.isFinite else { return .invalid }

        let monotonicSample = monotonicClock.now
        precondition(monotonicSample.isFinite)
        let wallSample = wallClock.now
        let remaining = wallDeadline.timeIntervalSince(wallSample)

        guard remaining.isFinite else { return .invalid }
        guard remaining > 0 else { return .expired }
        guard remaining <= TimeInterval(totalSeconds) else { return .invalid }
        guard remaining < Double(Int.max) else { return .invalid }

        frozenRemaining = remaining
        state.restore(
            totalSeconds: totalSeconds,
            secondsRemaining: Int(ceil(remaining))
        )
        activeRun = ActiveRun(
            id: nextRunID(),
            monotonicDeadline: monotonicSample + remaining,
            wallDeadline: wallDeadline
        )
        return .restored
    }

    @discardableResult
    func restoreFrozen(
        totalSeconds: Int,
        exactRemaining: TimeInterval
    ) -> Bool {
        guard activeRun == nil else { return false }
        guard totalSeconds > 0 else { return false }
        guard exactRemaining.isFinite, exactRemaining > 0 else { return false }
        guard exactRemaining <= TimeInterval(totalSeconds) else { return false }
        guard exactRemaining < Double(Int.max) else { return false }

        frozenRemaining = exactRemaining
        state.restore(
            totalSeconds: totalSeconds,
            secondsRemaining: Int(ceil(exactRemaining))
        )
        return true
    }

    @discardableResult
    func armRefreshPublisher() -> Bool {
        guard let run = activeRun else { return false }
        guard timerCancellable == nil else { return false }

        generation &+= 1
        let expectedGeneration = generation
        let expectedRunID = run.id
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard self.generation == expectedGeneration else { return }
                guard self.activeRun?.id == expectedRunID else { return }
                self.refresh()
            }
        return true
    }

    private func nextRunID() -> UInt64 {
        lastRunID &+= 1
        return lastRunID
    }

    private func discardActiveRunWithoutRefresh() {
        invalidatePublisherAndActiveRun()
    }

    private func invalidatePublisherAndActiveRun(expectedRunID: UInt64? = nil) {
        if let expectedRunID, activeRun?.id != expectedRunID {
            return
        }
        generation &+= 1
        timerCancellable?.cancel()
        timerCancellable = nil
        activeRun = nil
    }
}
