import Foundation

enum TimerType: String, Codable {
    case regular
    case breakTimer
}

@Observable
final class TimerState {
    var secondsRemaining: Int
    var totalSeconds: Int
    var isRunning: Bool
    var timerType: TimerType

    init(secondsRemaining: Int = 0, totalSeconds: Int = 0, isRunning: Bool = false, timerType: TimerType = .regular) {
        self.secondsRemaining = secondsRemaining
        self.totalSeconds = totalSeconds
        self.isRunning = isRunning
        self.timerType = timerType
    }

    var displayTime: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0.0 }
        return Double(totalSeconds - secondsRemaining) / Double(totalSeconds)
    }
}
