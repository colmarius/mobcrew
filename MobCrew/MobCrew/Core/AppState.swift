import Foundation

@MainActor
@Observable
final class AppState {
    static let timerDurationMinutesRange = 1...60

    let roster: Roster
    let timerState: TimerState
    private(set) var sessionPhase: SessionPhase = .regularIdle
    private(set) var timerDuration: Int {
        didSet {
            persistenceService.saveTimerDuration(timerDuration)
        }
    }

    // Break system properties
    var breakInterval: Int = 5 {
        didSet {
            persistenceService.saveBreakInterval(breakInterval)
        }
    }
    var breakDuration: Int = 300 {
        didSet {
            persistenceService.saveBreakDuration(breakDuration)
        }
    }
    private(set) var breaksEnabled: Bool
    private(set) var turnsSinceBreak: Int = 0
    var currentTip: Tip = Tip.random()
    var notificationsEnabled: Bool = true {
        didSet {
            persistenceService.saveNotificationsEnabled(notificationsEnabled)
        }
    }
    var showTips: Bool = false {
        didSet {
            persistenceService.saveShowTips(showTips)
        }
    }

    private let persistenceService: PersistenceService
    private let notificationService: any NotificationServiceProtocol
    private let activeMobstersFileService: any ActiveMobstersFileServiceProtocol
    private let timerEngine: TimerEngine
    private var hasRequestedNotificationPermission = false

    init(
        persistenceService: PersistenceService = PersistenceService(),
        notificationService: any NotificationServiceProtocol = NotificationService.shared,
        activeMobstersFileService: any ActiveMobstersFileServiceProtocol = ActiveMobstersFileService(),
        timerEngine: TimerEngine = TimerEngine()
    ) {
        self.persistenceService = persistenceService
        self.notificationService = notificationService
        self.activeMobstersFileService = activeMobstersFileService
        self.timerEngine = timerEngine

        let loadedRoster = persistenceService.loadRoster()
        let loadedDuration = persistenceService.loadTimerDuration() ?? 420 // 7 minutes default
        let loadedBreakInterval = persistenceService.loadBreakInterval() ?? 5
        let loadedBreakDuration = persistenceService.loadBreakDuration() ?? 300 // 5 minutes default
        let loadedBreaksEnabled = persistenceService.loadBreaksEnabled() ?? true
        let loadedNotificationsEnabled = persistenceService.loadNotificationsEnabled() ?? true
        let loadedShowTips = persistenceService.loadShowTips() ?? false

        self.roster = loadedRoster
        self.notificationsEnabled = loadedNotificationsEnabled
        self.showTips = loadedShowTips
        self.timerDuration = loadedDuration
        self.breakInterval = loadedBreakInterval
        self.breakDuration = loadedBreakDuration
        self.breaksEnabled = loadedBreaksEnabled
        self.timerState = timerEngine.state
        timerEngine.reset(duration: loadedDuration)

        setupBindings()
    }

    var isOnBreak: Bool {
        sessionPhase.isBreak
    }

    var isRunning: Bool {
        sessionPhase.isRunning
    }

    var primaryAction: SessionPrimaryAction {
        switch sessionPhase {
        case .regularIdle:
            .start
        case .regularRunning, .breakRunning:
            .pause
        case .regularPaused, .breakPaused:
            .resume
        case .breakDue:
            .takeBreak
        }
    }

    var primaryActionLabel: String {
        switch sessionPhase {
        case .regularIdle:
            "Start"
        case .regularRunning:
            "Pause"
        case .regularPaused:
            "Resume"
        case .breakDue:
            "Take Break"
        case .breakRunning:
            "Pause Break"
        case .breakPaused:
            "Resume Break"
        }
    }

    var primaryActionSystemImage: String {
        switch primaryAction {
        case .start, .resume:
            "play.fill"
        case .pause:
            "pause.fill"
        case .takeBreak:
            "cup.and.saucer.fill"
        }
    }

    var canPerformPrimaryAction: Bool {
        switch sessionPhase {
        case .regularIdle, .regularPaused:
            !roster.activeMobsters.isEmpty
        case .regularRunning, .breakDue, .breakRunning, .breakPaused:
            true
        }
    }

    var canResetTimer: Bool {
        sessionPhase.isRegular
    }

    var canSkipTurn: Bool {
        sessionPhase.isRegular && roster.activeMobsters.count >= 2
    }

    var canSkipBreak: Bool {
        sessionPhase.isBreak
    }

    var skipActionLabel: String {
        sessionPhase.isBreak ? "Skip Break" : "Skip Turn"
    }

    var canPerformSkipAction: Bool {
        sessionPhase.isBreak ? canSkipBreak : canSkipTurn
    }

    private func setupBindings() {
        timerEngine.configure(onComplete: { [weak self] in
            self?.handleTimerComplete()
        })
    }

    private func handleTimerComplete() {
        switch sessionPhase {
        case .regularRunning:
            completeRegularTurn()
        case .breakRunning:
            completeBreak()
        case .regularIdle, .regularPaused, .breakDue, .breakPaused:
            return
        }
    }

    private func completeRegularTurn() {
        sessionPhase = .regularIdle
        let shouldAdvanceRoles = roster.activeMobsters.count >= 2
        if shouldAdvanceRoles {
            roster.advanceTurn()
        }
        if breaksEnabled {
            turnsSinceBreak += 1
        } else {
            turnsSinceBreak = 0
        }

        if breaksEnabled && turnsSinceBreak >= breakInterval {
            timerEngine.reset(duration: breakDuration)
            sessionPhase = .breakDue
        } else {
            timerEngine.reset(duration: timerDuration)
        }

        if shouldAdvanceRoles {
            updateActiveMobstersFile()
        }
        if sessionPhase == .breakDue {
            sendBreakDueNotification()
        } else {
            sendTimerCompleteNotification()
        }
    }

    private func sendTimerCompleteNotification() {
        guard notificationsEnabled else { return }
        let driver = roster.driver?.name ?? "Next Driver"
        let navigator = roster.navigator?.name ?? "Next Navigator"
        notificationService.sendTimerComplete(driver: driver, navigator: navigator)
    }

    private func sendBreakDueNotification() {
        guard notificationsEnabled else { return }
        notificationService.sendBreakDue(duration: breakDuration)
    }

    private func completeBreak() {
        sessionPhase = .regularIdle
        turnsSinceBreak = 0
        timerEngine.reset(duration: timerDuration)
        sendBreakCompleteNotification()
    }

    private func sendBreakCompleteNotification() {
        guard notificationsEnabled else { return }
        notificationService.sendBreakComplete()
    }

    func performPrimaryAction() {
        switch primaryAction {
        case .start:
            startTimer()
        case .pause:
            pauseTimer()
        case .resume:
            resumeTimer()
        case .takeBreak:
            takeBreak()
        }
    }

    func performSkipAction() {
        if sessionPhase.isBreak {
            skipBreak()
        } else {
            skipTurn()
        }
    }

    func startTimer() {
        guard sessionPhase == .regularIdle else { return }
        guard !roster.activeMobsters.isEmpty else { return }
        guard timerState.secondsRemaining > 0 else { return }

        sessionPhase = .regularRunning
        guard timerEngine.start() else {
            sessionPhase = .regularIdle
            return
        }
        currentTip = Tip.random()
        requestNotificationPermissionIfNeeded()
    }

    func pauseTimer() {
        let pausedPhase: SessionPhase
        switch sessionPhase {
        case .regularRunning:
            pausedPhase = .regularPaused
        case .breakRunning:
            pausedPhase = .breakPaused
        case .regularIdle, .regularPaused, .breakDue, .breakPaused:
            return
        }

        switch timerEngine.pause() {
        case .paused:
            sessionPhase = pausedPhase
        case .completed:
            break
        case .inactive:
            assertionFailure("Running session phase has no active timer deadline")
        }
    }

    func resumeTimer() {
        let pausedPhase = sessionPhase
        let runningPhase: SessionPhase
        switch pausedPhase {
        case .regularPaused:
            guard !roster.activeMobsters.isEmpty else { return }
            runningPhase = .regularRunning
        case .breakPaused:
            runningPhase = .breakRunning
        case .regularIdle, .regularRunning, .breakDue, .breakRunning:
            return
        }
        guard timerState.secondsRemaining > 0 else { return }

        sessionPhase = runningPhase
        guard timerEngine.start() else {
            sessionPhase = pausedPhase
            return
        }
    }

    func resetTimer() {
        guard sessionPhase.isRegular else { return }
        sessionPhase = .regularIdle
        timerEngine.reset(duration: timerDuration)
    }

    func setTimerDuration(minutes: Int) {
        guard Self.timerDurationMinutesRange.contains(minutes) else { return }
        timerDuration = minutes * 60
        if sessionPhase == .regularIdle {
            timerEngine.reset(duration: timerDuration)
        }
    }

    func setBreaksEnabled(_ enabled: Bool) {
        guard breaksEnabled != enabled else { return }
        breaksEnabled = enabled
        persistenceService.saveBreaksEnabled(enabled)

        guard !enabled else { return }
        turnsSinceBreak = 0
        if sessionPhase == .breakDue {
            sessionPhase = .regularIdle
            timerEngine.reset(duration: timerDuration)
        }
    }

    func takeBreak() {
        guard sessionPhase == .breakDue else { return }
        guard timerState.secondsRemaining > 0 else { return }

        sessionPhase = .breakRunning
        guard timerEngine.start() else {
            sessionPhase = .breakDue
            return
        }
    }

    func skipBreak() {
        guard sessionPhase.isBreak else { return }
        sessionPhase = .regularIdle
        turnsSinceBreak = 0
        timerEngine.reset(duration: timerDuration)
    }

    func saveRoster() {
        persistenceService.saveRoster(roster)
        activeMobstersFileService.writeActiveMobsters(roster)
    }

    func updateActiveMobstersFile() {
        activeMobstersFileService.writeActiveMobsters(roster)
    }

    private func requestNotificationPermissionIfNeeded() {
        guard notificationsEnabled else { return }
        guard !hasRequestedNotificationPermission else { return }
        hasRequestedNotificationPermission = true
        notificationService.requestPermission()
    }

    func skipTurn() {
        guard canSkipTurn else { return }

        sessionPhase = .regularIdle
        timerEngine.reset(duration: timerDuration)
        roster.advanceTurn()
        sessionPhase = .regularRunning
        guard timerEngine.start() else {
            sessionPhase = .regularIdle
            return
        }
        currentTip = Tip.random()
        requestNotificationPermissionIfNeeded()
        updateActiveMobstersFile()
    }

    static func previewing(_ sessionPhase: SessionPhase) -> AppState {
        let appState = AppState()
        appState.sessionPhase = sessionPhase
        if sessionPhase.isBreak {
            appState.timerEngine.reset(duration: appState.breakDuration)
        }
        return appState
    }
}
