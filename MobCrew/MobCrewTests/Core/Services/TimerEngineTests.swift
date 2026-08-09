import Testing
import Foundation
@testable import MobCrew

private final class TestMonotonicClock: MonotonicClockProtocol {
    var now: TimeInterval = 0

    func advance(by duration: TimeInterval) {
        now += duration
    }
}

private final class TestWallClock: WallClockProtocol {
    var current: Date
    private(set) var readCount = 0

    init(now: Date = Date(timeIntervalSinceReferenceDate: 1_000)) {
        self.current = now
    }

    var now: Date {
        readCount += 1
        return current
    }
}

@MainActor
@Suite("TimerEngine Tests")
struct TimerEngineTests {
    private struct Fixture {
        let engine: TimerEngine
        let monotonicClock: TestMonotonicClock
        let wallClock: TestWallClock
    }

    private func makeFixture(duration: Int = 0) -> Fixture {
        let monotonicClock = TestMonotonicClock()
        let wallClock = TestWallClock()
        let engine = TimerEngine(
            monotonicClock: monotonicClock,
            wallClock: wallClock
        )
        if duration > 0 {
            engine.reset(duration: duration)
        }
        return Fixture(
            engine: engine,
            monotonicClock: monotonicClock,
            wallClock: wallClock
        )
    }

    @Test("initial state has zero seconds and is inactive")
    func initialStateIsZero() {
        let fixture = makeFixture()

        #expect(fixture.engine.secondsRemaining == 0)
        #expect(fixture.engine.isRunning == false)
        #expect(fixture.engine.runningWallDeadline == nil)
        #expect(fixture.engine.frozenExactRemaining == 0)
    }

    @Test("reset replaces duration and discards an active run")
    func resetReplacesActiveRun() {
        let fixture = makeFixture(duration: 60)
        fixture.engine.start()
        fixture.monotonicClock.advance(by: 10)

        fixture.engine.reset(duration: 120)

        #expect(fixture.engine.isRunning == false)
        #expect(fixture.engine.secondsRemaining == 120)
        #expect(fixture.engine.state.totalSeconds == 120)
        #expect(fixture.engine.frozenExactRemaining == 120)
        #expect(fixture.engine.refresh() == .inactive)
    }

    @Test("start establishes monotonic and wall deadlines")
    func startEstablishesDeadlines() {
        let fixture = makeFixture(duration: 60)
        let expectedWallDeadline = fixture.wallClock.current.addingTimeInterval(60)

        #expect(fixture.engine.start())

        #expect(fixture.engine.isRunning)
        #expect(fixture.engine.runningWallDeadline == expectedWallDeadline)
        #expect(fixture.engine.frozenExactRemaining == nil)
        #expect(fixture.wallClock.readCount == 1)
        #expect(fixture.engine.start() == false)
        fixture.engine.reset(duration: 60)
    }

    @Test("start rejects an empty countdown")
    func startRejectsZero() {
        let fixture = makeFixture()

        #expect(fixture.engine.start() == false)
        #expect(fixture.engine.isRunning == false)
        #expect(fixture.wallClock.readCount == 0)
    }

    @Test("one delayed refresh derives all elapsed time from the deadline")
    func delayedRefresh() {
        let fixture = makeFixture(duration: 10)
        fixture.engine.start()

        fixture.monotonicClock.advance(by: 3.4)
        let result = fixture.engine.refresh()

        #expect(result == .active)
        #expect(fixture.engine.secondsRemaining == 7)
        #expect(fixture.engine.state.totalSeconds == 10)
        #expect(fixture.wallClock.readCount == 1)
        fixture.engine.reset(duration: 10)
    }

    @Test("display rounding uses ceil until the exact deadline")
    func ceilBoundaries() {
        let fixture = makeFixture(duration: 2)
        fixture.engine.start()

        fixture.monotonicClock.advance(by: 0.9999)
        fixture.engine.refresh()
        #expect(fixture.engine.secondsRemaining == 2)

        fixture.monotonicClock.advance(by: 0.0001)
        fixture.engine.refresh()
        #expect(fixture.engine.secondsRemaining == 1)

        fixture.monotonicClock.advance(by: 0.9999)
        fixture.engine.refresh()
        #expect(fixture.engine.secondsRemaining == 1)

        fixture.monotonicClock.advance(by: 0.0001)
        #expect(fixture.engine.refresh() == .completed)
        #expect(fixture.engine.secondsRemaining == 0)
    }

    @Test("sleep-like jump completes exactly once")
    func sleepLikeJumpCompletesOnce() {
        let fixture = makeFixture(duration: 5)
        var completionCount = 0
        fixture.engine.configure {
            completionCount += 1
        }
        fixture.engine.start()

        fixture.monotonicClock.advance(by: 30)
        #expect(fixture.engine.refresh() == .completed)
        #expect(fixture.engine.refresh() == .inactive)

        #expect(completionCount == 1)
        #expect(fixture.engine.isRunning == false)
        #expect(fixture.engine.secondsRemaining == 0)
    }

    @Test("pause and resume preserve exact fractional remaining time")
    func pauseResumeDoesNotInflateTime() {
        let fixture = makeFixture(duration: 1)
        var completionCount = 0
        fixture.engine.configure {
            completionCount += 1
        }
        fixture.engine.start()
        fixture.monotonicClock.advance(by: 0.4)

        #expect(fixture.engine.pause() == .paused)
        #expect(fixture.engine.secondsRemaining == 1)
        #expect(abs((fixture.engine.frozenExactRemaining ?? 0) - 0.6) < 0.000_001)

        for _ in 0..<3 {
            #expect(fixture.engine.start())
            #expect(fixture.engine.pause() == .paused)
        }

        #expect(abs((fixture.engine.frozenExactRemaining ?? 0) - 0.6) < 0.000_001)
        fixture.engine.start()
        fixture.monotonicClock.advance(by: 0.5999)
        #expect(fixture.engine.refresh() == .active)
        #expect(fixture.engine.secondsRemaining == 1)
        fixture.monotonicClock.advance(by: 0.0001)
        #expect(fixture.engine.refresh() == .completed)
        #expect(completionCount == 1)
    }

    @Test("pause at the deadline lets completion win")
    func pauseAtDeadlineCompletes() {
        let fixture = makeFixture(duration: 1)
        var completionCount = 0
        fixture.engine.configure {
            completionCount += 1
        }
        fixture.engine.start()
        fixture.monotonicClock.advance(by: 1)

        #expect(fixture.engine.pause() == .completed)

        #expect(completionCount == 1)
        #expect(fixture.engine.isRunning == false)
        #expect(fixture.engine.secondsRemaining == 0)
    }

    @Test("explicit reset discards an overdue cycle without completing it")
    func resetDiscardsOverdueCycle() {
        let fixture = makeFixture(duration: 1)
        var completionCount = 0
        fixture.engine.configure {
            completionCount += 1
        }
        fixture.engine.start()
        fixture.monotonicClock.advance(by: 5)

        fixture.engine.reset(duration: 10)

        #expect(completionCount == 0)
        #expect(fixture.engine.refresh() == .inactive)
        #expect(fixture.engine.secondsRemaining == 10)
    }

    @Test("completion callback can install a replacement cycle")
    func reentrantCompletionPreservesReplacementCycle() {
        let fixture = makeFixture(duration: 1)
        var completionCount = 0
        fixture.engine.configure {
            completionCount += 1
            fixture.engine.reset(duration: 2)
            fixture.engine.start()
        }
        fixture.engine.start()
        fixture.monotonicClock.advance(by: 1)

        #expect(fixture.engine.refresh() == .completed)

        #expect(completionCount == 1)
        #expect(fixture.engine.isRunning)
        #expect(fixture.engine.secondsRemaining == 2)
        #expect(fixture.engine.state.totalSeconds == 2)
        fixture.engine.reset(duration: 2)
    }

    @Test("normal refreshes never reconcile against wall time")
    func wallClockIsIsolatedFromInProcessRefresh() {
        let fixture = makeFixture(duration: 10)
        fixture.engine.start()
        #expect(fixture.wallClock.readCount == 1)

        fixture.monotonicClock.advance(by: 3)
        fixture.engine.refresh()
        fixture.wallClock.current = fixture.wallClock.current.addingTimeInterval(10_000)
        fixture.monotonicClock.advance(by: 2)
        fixture.engine.refresh()

        #expect(fixture.engine.secondsRemaining == 5)
        #expect(fixture.wallClock.readCount == 1)

        #expect(fixture.engine.pause() == .paused)
        #expect(fixture.wallClock.readCount == 1)
        fixture.engine.start()
        #expect(fixture.wallClock.readCount == 2)
        fixture.engine.reset(duration: 10)
    }

    @Test("valid wall deadline restores once into a monotonic run before arming")
    func validRestore() {
        let fixture = makeFixture(duration: 7)
        var completionCount = 0
        fixture.engine.configure {
            completionCount += 1
        }
        let wallDeadline = fixture.wallClock.current.addingTimeInterval(5)

        let result = fixture.engine.restoreRunning(
            totalSeconds: 10,
            wallDeadline: wallDeadline
        )

        #expect(result == .restored)
        #expect(fixture.engine.isRunning)
        #expect(fixture.engine.secondsRemaining == 5)
        #expect(fixture.engine.state.totalSeconds == 10)
        #expect(fixture.engine.runningWallDeadline == wallDeadline)
        #expect(fixture.wallClock.readCount == 1)
        #expect(fixture.engine.armRefreshPublisher())
        #expect(fixture.engine.armRefreshPublisher() == false)

        fixture.monotonicClock.advance(by: 5)
        #expect(fixture.engine.refresh() == .completed)
        #expect(completionCount == 1)
    }

    @Test("restored run ignores later wall-clock jumps")
    func restoredRunUsesOnlyMonotonicTime() {
        let fixture = makeFixture(duration: 7)
        let wallDeadline = fixture.wallClock.current.addingTimeInterval(5)
        #expect(fixture.engine.restoreRunning(totalSeconds: 10, wallDeadline: wallDeadline) == .restored)
        fixture.wallClock.current = fixture.wallClock.current.addingTimeInterval(1_000_000)

        fixture.monotonicClock.advance(by: 2)
        #expect(fixture.engine.refresh() == .active)

        #expect(fixture.engine.secondsRemaining == 3)
        #expect(fixture.wallClock.readCount == 1)
        fixture.engine.reset(duration: 7)
    }

    @Test("expired and invalid restores do not mutate prepared state")
    func rejectedRestoreDoesNotMutate() {
        let baseDate = Date(timeIntervalSinceReferenceDate: 1_000)
        let cases: [(Int, Date, RunningTimerRestoreResult)] = [
            (10, baseDate, .expired),
            (10, baseDate.addingTimeInterval(-1), .expired),
            (10, baseDate.addingTimeInterval(11), .invalid),
            (0, baseDate.addingTimeInterval(1), .invalid),
            (10, Date(timeIntervalSinceReferenceDate: .infinity), .invalid)
        ]

        for (totalSeconds, deadline, expectedResult) in cases {
            let monotonicClock = TestMonotonicClock()
            let wallClock = TestWallClock(now: baseDate)
            let state = TimerState(secondsRemaining: 7, totalSeconds: 7)
            let engine = TimerEngine(
                state: state,
                monotonicClock: monotonicClock,
                wallClock: wallClock
            )
            var completionCount = 0
            engine.configure {
                completionCount += 1
            }

            let result = engine.restoreRunning(
                totalSeconds: totalSeconds,
                wallDeadline: deadline
            )

            #expect(result == expectedResult)
            #expect(engine.isRunning == false)
            #expect(engine.state.totalSeconds == 7)
            #expect(engine.secondsRemaining == 7)
            #expect(engine.frozenExactRemaining == 7)
            #expect(completionCount == 0)
        }
    }

    @Test("fractional restored remainder uses ceil display")
    func fractionalRestoreRounding() {
        let fixture = makeFixture(duration: 7)
        let wallDeadline = fixture.wallClock.current.addingTimeInterval(1.2)

        #expect(fixture.engine.restoreRunning(totalSeconds: 5, wallDeadline: wallDeadline) == .restored)
        #expect(fixture.engine.secondsRemaining == 2)

        fixture.monotonicClock.advance(by: 0.2)
        fixture.engine.refresh()
        #expect(fixture.engine.secondsRemaining == 1)

        fixture.monotonicClock.advance(by: 1)
        #expect(fixture.engine.refresh() == .completed)
    }

    @Test("refresh after pause is inactive even if the old deadline passes")
    func staleRefreshAfterPause() {
        let fixture = makeFixture(duration: 5)
        fixture.engine.start()
        #expect(fixture.engine.pause() == .paused)
        fixture.monotonicClock.advance(by: 10)

        #expect(fixture.engine.refresh() == .inactive)
        #expect(fixture.engine.secondsRemaining == 5)
    }
}
