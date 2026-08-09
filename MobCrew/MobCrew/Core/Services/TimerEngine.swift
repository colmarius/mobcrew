import Foundation
import Combine

@MainActor
@Observable
final class TimerEngine {
    private(set) var state: TimerState
    private var timerCancellable: AnyCancellable?
    private var onComplete: (@MainActor () -> Void)?
    private var generation = 0

    var isRunning: Bool {
        timerCancellable != nil
    }

    var secondsRemaining: Int {
        state.secondsRemaining
    }

    init(state: TimerState = TimerState()) {
        self.state = state
    }

    func configure(onComplete: @escaping @MainActor () -> Void) {
        self.onComplete = onComplete
    }

    func reset(duration: Int) {
        stop()
        state.reset(duration: duration)
    }

    @discardableResult
    func start() -> Bool {
        guard timerCancellable == nil else { return false }
        guard state.secondsRemaining > 0 else { return false }

        generation += 1
        let expectedGeneration = generation

        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.generation == expectedGeneration else { return }
                self.processTick()
            }
        return true
    }

    func stop() {
        generation += 1
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func toggle() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }

    func processTick() {
        guard isRunning else { return }
        guard state.secondsRemaining > 0 else {
            complete()
            return
        }

        state.elapseOneSecond()

        if state.secondsRemaining == 0 {
            complete()
        }
    }

    private func complete() {
        stop()
        onComplete?()
    }
}
