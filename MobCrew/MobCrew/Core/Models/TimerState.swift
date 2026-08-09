import Foundation

enum SessionPhase: String, Codable, CaseIterable, Hashable, Sendable {
    case regularIdle
    case regularRunning
    case regularPaused
    case breakDue
    case breakRunning
    case breakPaused

    var isRegular: Bool {
        switch self {
        case .regularIdle, .regularRunning, .regularPaused:
            true
        case .breakDue, .breakRunning, .breakPaused:
            false
        }
    }

    var isBreak: Bool {
        !isRegular
    }

    var isRunning: Bool {
        self == .regularRunning || self == .breakRunning
    }
}

enum SessionPrimaryAction: Hashable, Sendable {
    case start
    case pause
    case resume
    case takeBreak
}

@Observable
final class TimerState {
    private(set) var secondsRemaining: Int
    private(set) var totalSeconds: Int

    init(secondsRemaining: Int = 0, totalSeconds: Int = 0) {
        self.secondsRemaining = secondsRemaining
        self.totalSeconds = totalSeconds
    }

    func reset(duration: Int) {
        secondsRemaining = duration
        totalSeconds = duration
    }

    func updateRemaining(_ seconds: Int) {
        secondsRemaining = max(0, seconds)
    }

    func restore(totalSeconds: Int, secondsRemaining: Int) {
        self.totalSeconds = totalSeconds
        self.secondsRemaining = secondsRemaining
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
