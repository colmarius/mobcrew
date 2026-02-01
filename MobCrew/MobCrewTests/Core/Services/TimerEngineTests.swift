import Testing
import Foundation
@testable import MobCrew

@Suite("TimerEngine Tests")
struct TimerEngineTests {

    // MARK: - Initial State

    @Test("initial state has zero seconds and is not running")
    func initialStateIsZero() {
        let engine = TimerEngine()

        #expect(engine.secondsRemaining == 0)
        #expect(engine.isRunning == false)
    }

    // MARK: - Reset

    @Test("reset sets duration and stops timer")
    func resetSetsDuration() {
        let engine = TimerEngine()

        engine.reset(duration: 300)

        #expect(engine.secondsRemaining == 300)
        #expect(engine.state.totalSeconds == 300)
        #expect(engine.isRunning == false)
    }

    @Test("reset stops a running timer")
    func resetStopsRunningTimer() {
        let engine = TimerEngine()
        engine.reset(duration: 60)
        engine.start()

        #expect(engine.isRunning == true)

        engine.reset(duration: 120)

        #expect(engine.isRunning == false)
        #expect(engine.secondsRemaining == 120)
    }

    // MARK: - Start/Stop

    @Test("start sets isRunning to true")
    func startSetsIsRunning() {
        let engine = TimerEngine()
        engine.reset(duration: 60)

        engine.start()

        #expect(engine.isRunning == true)

        engine.stop()
    }

    @Test("start does nothing when already running")
    func startDoesNothingWhenRunning() {
        let engine = TimerEngine()
        engine.reset(duration: 60)
        engine.start()

        engine.start()

        #expect(engine.isRunning == true)

        engine.stop()
    }

    @Test("start does nothing when seconds is zero")
    func startDoesNothingWhenZeroSeconds() {
        let engine = TimerEngine()

        engine.start()

        #expect(engine.isRunning == false)
    }

    @Test("stop sets isRunning to false")
    func stopSetsIsNotRunning() {
        let engine = TimerEngine()
        engine.reset(duration: 60)
        engine.start()

        engine.stop()

        #expect(engine.isRunning == false)
    }

    // MARK: - Toggle

    @Test("toggle starts when stopped")
    func toggleStartsWhenStopped() {
        let engine = TimerEngine()
        engine.reset(duration: 60)

        engine.toggle()

        #expect(engine.isRunning == true)

        engine.stop()
    }

    @Test("toggle stops when running")
    func toggleStopsWhenRunning() {
        let engine = TimerEngine()
        engine.reset(duration: 60)
        engine.start()

        engine.toggle()

        #expect(engine.isRunning == false)
    }

    // MARK: - Pause/Resume

    @Test("pause preserves remaining time")
    func pausePreservesRemainingTime() {
        let engine = TimerEngine()
        engine.reset(duration: 60)
        engine.start()

        engine.stop()

        #expect(engine.secondsRemaining == 60)
        #expect(engine.isRunning == false)
    }

    @Test("resume continues from paused state")
    func resumeContinuesFromPausedState() {
        let engine = TimerEngine()
        engine.reset(duration: 60)
        engine.start()
        engine.stop()

        let remainingBeforeResume = engine.secondsRemaining
        engine.start()

        #expect(engine.isRunning == true)
        #expect(engine.secondsRemaining == remainingBeforeResume)

        engine.stop()
    }

    // MARK: - Countdown (async tests)

    @Test("countdown decrements seconds")
    func countdownDecrementsSeconds() async throws {
        let engine = TimerEngine()
        engine.reset(duration: 3)

        engine.start()

        try await Task.sleep(for: .milliseconds(1100))

        #expect(engine.secondsRemaining < 3)

        engine.stop()
    }

    // MARK: - Completion Callback

    @Test("completion callback fires when timer reaches zero")
    func completionCallbackFires() async throws {
        let engine = TimerEngine()
        var callbackFired = false

        engine.configure(onComplete: {
            callbackFired = true
        })

        engine.reset(duration: 1)
        engine.start()

        try await Task.sleep(for: .milliseconds(1500))

        #expect(callbackFired == true)
        #expect(engine.isRunning == false)
        #expect(engine.secondsRemaining == 0)
    }

    @Test("completion callback does not fire when stopped early")
    func completionCallbackDoesNotFireWhenStopped() async throws {
        let engine = TimerEngine()
        var callbackFired = false

        engine.configure(onComplete: {
            callbackFired = true
        })

        engine.reset(duration: 5)
        engine.start()

        try await Task.sleep(for: .milliseconds(100))
        engine.stop()

        try await Task.sleep(for: .milliseconds(500))

        #expect(callbackFired == false)
    }
}
