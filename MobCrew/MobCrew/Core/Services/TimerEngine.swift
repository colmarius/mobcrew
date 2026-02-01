import Foundation
import Combine

@Observable
final class TimerEngine {
    private(set) var state: TimerState
    private var timerCancellable: AnyCancellable?
    private var onComplete: (() -> Void)?

    var isRunning: Bool {
        state.isRunning
    }

    var secondsRemaining: Int {
        state.secondsRemaining
    }

    init(state: TimerState = TimerState()) {
        self.state = state
    }

    func configure(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    func reset(duration: Int) {
        stop()
        state.secondsRemaining = duration
        state.totalSeconds = duration
    }

    func start() {
        guard !state.isRunning else { return }
        guard state.secondsRemaining > 0 else { return }

        state.isRunning = true

        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil
        state.isRunning = false
    }

    func toggle() {
        if state.isRunning {
            stop()
        } else {
            start()
        }
    }

    private func tick() {
        guard state.secondsRemaining > 0 else {
            complete()
            return
        }

        state.secondsRemaining -= 1

        if state.secondsRemaining == 0 {
            complete()
        }
    }

    private func complete() {
        stop()
        onComplete?()
    }
}
