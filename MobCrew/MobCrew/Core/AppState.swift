import Foundation
import Accessibility

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

    private let persistenceService: any PersistenceServiceProtocol
    private let notificationService: any NotificationServiceProtocol
    private let activeMobstersFileService: any ActiveMobstersFileServiceProtocol
    private let timerEngine: TimerEngine
    private let accessibilityAnnouncer: @MainActor (String) -> Void
    private var hasRequestedNotificationPermission = false
    private var cycleID: UUID
    private var isDeferringRosterPersistence = false
    private var isRosterPersistencePending = false
    private var needsActiveMobstersFileWrite = false
    private var preservesUnknownSessionSnapshot = false

    init(
        persistenceService: any PersistenceServiceProtocol = PersistenceService(),
        notificationService: any NotificationServiceProtocol = NotificationService.shared,
        activeMobstersFileService: any ActiveMobstersFileServiceProtocol = ActiveMobstersFileService(),
        timerEngine: TimerEngine = TimerEngine(),
        accessibilityAnnouncer: @escaping @MainActor (String) -> Void = {
            AccessibilityNotification.Announcement($0).post()
        }
    ) {
        self.persistenceService = persistenceService
        self.notificationService = notificationService
        self.activeMobstersFileService = activeMobstersFileService
        self.timerEngine = timerEngine
        self.accessibilityAnnouncer = accessibilityAnnouncer

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
        self.cycleID = UUID()

        setupBindings()
        setupRosterPersistence()
        restoreSession()
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

    var timerAccessibilityLabel: String {
        sessionPhase.isBreak ? "Break timer" : "Turn timer"
    }

    var timerAccessibilityValue: String {
        Self.accessibilityDuration(timerState.secondsRemaining)
    }

    var timerAccessibilityHint: String {
        let state: String
        switch sessionPhase {
        case .regularIdle:
            state = "Ready to start."
        case .regularRunning:
            state = "Turn in progress."
        case .regularPaused:
            state = "Turn paused."
        case .breakDue:
            state = "Break ready to start."
        case .breakRunning:
            state = "Break in progress."
        case .breakPaused:
            state = "Break paused."
        }
        return "\(state) \(currentRoleSummary)"
    }

    var primaryActionAccessibilityLabel: String {
        switch sessionPhase {
        case .regularIdle:
            "Start turn timer"
        case .regularRunning:
            "Pause turn timer"
        case .regularPaused:
            "Resume turn timer"
        case .breakDue:
            "Take break"
        case .breakRunning:
            "Pause break timer"
        case .breakPaused:
            "Resume break timer"
        }
    }

    var primaryActionAccessibilityHint: String {
        switch sessionPhase {
        case .regularIdle:
            "Starts the configured turn. \(currentRoleSummary)"
        case .regularRunning:
            "Pauses the current turn without resetting it."
        case .regularPaused:
            "Continues the paused turn."
        case .breakDue:
            "Starts the optional break timer."
        case .breakRunning:
            "Pauses the break without resetting it."
        case .breakPaused:
            "Continues the paused break."
        }
    }

    var skipActionAccessibilityLabel: String {
        if sessionPhase.isBreak {
            return "Skip break"
        }
        if let nextDriver = roster.navigator?.name {
            return "Skip turn to \(nextDriver) as driver"
        }
        return "Skip turn"
    }

    var skipActionAccessibilityHint: String {
        sessionPhase.isBreak
            ? "Returns to the turn timer without advancing roles."
            : "Advances roles and immediately starts a fresh turn."
    }

    var resetTimerAccessibilityHint: String {
        "Resets this turn to \(Self.accessibilityDuration(timerDuration)) without advancing roles."
    }

    var canPerformSkipAction: Bool {
        sessionPhase.isBreak ? canSkipBreak : canSkipTurn
    }

    private func setupBindings() {
        timerEngine.configure(onComplete: { [weak self] in
            self?.handleTimerComplete()
        })
    }

    private func setupRosterPersistence() {
        roster.setMutationHandler { [weak self] in
            self?.handleRosterMutation()
        }
    }

    private func handleRosterMutation() {
        guard !isDeferringRosterPersistence else { return }
        _ = persistRosterThenSession(writeActiveFile: true)
    }

    private func withDeferredRosterPersistence(_ mutation: () -> Void) {
        precondition(!isDeferringRosterPersistence)
        isDeferringRosterPersistence = true
        defer { isDeferringRosterPersistence = false }
        mutation()
    }

    @discardableResult
    private func persistRosterThenSession(writeActiveFile: Bool) -> Bool {
        isRosterPersistencePending = true
        needsActiveMobstersFileWrite = needsActiveMobstersFileWrite || writeActiveFile
        return saveCurrentSessionSnapshot()
    }

    @discardableResult
    private func saveCurrentSessionSnapshot() -> Bool {
        guard persistPendingRosterIfNeeded() else { return false }
        guard !preservesUnknownSessionSnapshot else { return true }
        guard let snapshot = currentSessionSnapshot() else { return false }
        let didSave = persistenceService.saveSessionSnapshot(snapshot)
        return didSave
    }

    private func persistPendingRosterIfNeeded() -> Bool {
        guard isRosterPersistencePending else { return true }
        guard persistenceService.saveRoster(roster) else { return false }
        isRosterPersistencePending = false
        if needsActiveMobstersFileWrite {
            activeMobstersFileService.writeActiveMobsters(roster)
            needsActiveMobstersFileWrite = false
        }
        return true
    }

    private func currentSessionSnapshot() -> PersistedSessionSnapshot? {
        let timing: PersistedSessionTiming
        if sessionPhase.isRunning {
            guard let wallDeadline = timerEngine.runningWallDeadline else {
                assertionFailure("Running session phase has no wall deadline")
                return nil
            }
            timing = .running(wallDeadline: wallDeadline)
        } else {
            guard let exactRemaining = timerEngine.frozenExactRemaining else {
                assertionFailure("Non-running session phase has an active timer deadline")
                return nil
            }
            timing = .frozen(exactRemaining: exactRemaining)
        }

        return PersistedSessionSnapshot(
            version: PersistedSessionSnapshot.currentVersion,
            phase: sessionPhase,
            cycleID: cycleID,
            totalSeconds: timerState.totalSeconds,
            timing: timing,
            turnsSinceBreak: turnsSinceBreak
        )
    }

    private func restoreSession() {
        switch persistenceService.loadSessionSnapshot() {
        case .missing, .invalid:
            prepareFreshRegularSession()
            _ = saveCurrentSessionSnapshot()
        case .unknownNewer:
            preservesUnknownSessionSnapshot = true
            prepareFreshRegularSession()
        case .current(let snapshot):
            restoreCurrentSessionSnapshot(snapshot)
        }
    }

    private func restoreCurrentSessionSnapshot(_ snapshot: PersistedSessionSnapshot) {
        guard isValid(snapshot) else {
            prepareFreshRegularSession()
            _ = saveCurrentSessionSnapshot()
            return
        }

        turnsSinceBreak = snapshot.turnsSinceBreak
        cycleID = snapshot.cycleID

        let runningRestoreResult: RunningTimerRestoreResult?
        switch snapshot.timing {
        case .frozen:
            runningRestoreResult = nil
        case .running(let wallDeadline):
            sessionPhase = snapshot.phase
            let result = timerEngine.restoreRunning(
                totalSeconds: snapshot.totalSeconds,
                wallDeadline: wallDeadline
            )
            guard result != .invalid else {
                prepareFreshRegularSession()
                _ = saveCurrentSessionSnapshot()
                return
            }
            runningRestoreResult = result
        }

        if let receipt = roster.lastRegularCycleResolution,
           receipt.cycleID == snapshot.cycleID,
           snapshot.phase.isRegular {
            switch receipt.resolution {
            case .completed where snapshot.phase == .regularRunning:
                sessionPhase = .regularRunning
                completeRegularTurn(
                    cycleAlreadyResolved: true,
                    repairActiveFile: true,
                    announceTransition: false
                )
                return
            case .skipped:
                prepareFreshRegularSession(turnsSinceBreak: snapshot.turnsSinceBreak)
                _ = persistRosterThenSession(writeActiveFile: true)
                return
            case .completed:
                prepareFreshRegularSession()
                _ = persistRosterThenSession(writeActiveFile: true)
                return
            }
        }

        if snapshot.phase == .breakDue, !breaksEnabled {
            prepareFreshRegularSession()
            _ = saveCurrentSessionSnapshot()
            return
        }

        switch snapshot.timing {
        case .frozen(let exactRemaining):
            if snapshot.phase == .regularIdle {
                prepareFreshRegularSession(turnsSinceBreak: snapshot.turnsSinceBreak)
                _ = saveCurrentSessionSnapshot()
                return
            }
            guard timerEngine.restoreFrozen(
                totalSeconds: snapshot.totalSeconds,
                exactRemaining: exactRemaining
            ) else {
                prepareFreshRegularSession()
                _ = saveCurrentSessionSnapshot()
                return
            }
            sessionPhase = snapshot.phase
            _ = saveCurrentSessionSnapshot()
        case .running:
            guard let runningRestoreResult else {
                assertionFailure("Running snapshot has no staged restoration result")
                prepareFreshRegularSession()
                _ = saveCurrentSessionSnapshot()
                return
            }
            switch runningRestoreResult {
            case .restored:
                guard persistRosterThenSession(writeActiveFile: true) else {
                    prepareFreshRegularSession()
                    return
                }
                _ = timerEngine.armRefreshPublisher()
            case .expired:
                if snapshot.phase == .regularRunning {
                    completeRegularTurn(announceTransition: false)
                } else {
                    completeBreak(announceTransition: false)
                }
            case .invalid:
                assertionFailure("Invalid running restoration reached reconciliation")
                prepareFreshRegularSession()
                _ = saveCurrentSessionSnapshot()
            }
        }
    }

    private func isValid(_ snapshot: PersistedSessionSnapshot) -> Bool {
        guard snapshot.version == PersistedSessionSnapshot.currentVersion else { return false }
        guard (1...PersistedSessionSnapshot.maximumCycleSeconds).contains(snapshot.totalSeconds) else {
            return false
        }
        guard snapshot.turnsSinceBreak >= 0, snapshot.turnsSinceBreak < Int.max else { return false }

        switch snapshot.timing {
        case .frozen(let exactRemaining):
            guard !snapshot.phase.isRunning else { return false }
            guard exactRemaining.isFinite, exactRemaining > 0 else { return false }
            guard exactRemaining <= TimeInterval(snapshot.totalSeconds) else { return false }
            if snapshot.phase == .regularIdle || snapshot.phase == .breakDue {
                guard exactRemaining == TimeInterval(snapshot.totalSeconds) else { return false }
            }
        case .running(let wallDeadline):
            guard snapshot.phase.isRunning else { return false }
            guard wallDeadline.timeIntervalSinceReferenceDate.isFinite else { return false }
        }
        return true
    }

    private func prepareFreshRegularSession(turnsSinceBreak: Int = 0) {
        sessionPhase = .regularIdle
        self.turnsSinceBreak = turnsSinceBreak
        cycleID = UUID()
        timerEngine.reset(duration: timerDuration)
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

    private func completeRegularTurn(
        cycleAlreadyResolved: Bool = false,
        repairActiveFile: Bool = false,
        announceTransition: Bool = true
    ) {
        let completedCycleID = cycleID
        sessionPhase = .regularIdle
        let shouldAdvanceRoles = roster.activeMobsters.count >= 2
        if !cycleAlreadyResolved {
            withDeferredRosterPersistence {
                roster.resolveRegularCycle(
                    id: completedCycleID,
                    resolution: .completed,
                    advanceRoles: shouldAdvanceRoles
                )
            }
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
        cycleID = UUID()

        guard persistRosterThenSession(
            writeActiveFile: shouldAdvanceRoles || repairActiveFile
        ) else { return }
        if sessionPhase == .breakDue {
            if announceTransition {
                accessibilityAnnouncer(breakDueAnnouncement)
            }
            sendBreakDueNotification()
        } else {
            if announceTransition {
                accessibilityAnnouncer("Turn complete. \(currentRoleSummary)")
            }
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

    private func completeBreak(announceTransition: Bool = true) {
        sessionPhase = .regularIdle
        turnsSinceBreak = 0
        cycleID = UUID()
        timerEngine.reset(duration: timerDuration)
        guard saveCurrentSessionSnapshot() else { return }
        if announceTransition {
            accessibilityAnnouncer("Break complete. \(currentRoleSummary)")
        }
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
        _ = saveCurrentSessionSnapshot()
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
            _ = saveCurrentSessionSnapshot()
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
        _ = saveCurrentSessionSnapshot()
    }

    func resetTimer() {
        guard sessionPhase.isRegular else { return }
        sessionPhase = .regularIdle
        cycleID = UUID()
        timerEngine.reset(duration: timerDuration)
        _ = saveCurrentSessionSnapshot()
    }

    func setTimerDuration(minutes: Int) {
        guard Self.timerDurationMinutesRange.contains(minutes) else { return }
        timerDuration = minutes * 60
        if sessionPhase == .regularIdle {
            cycleID = UUID()
            timerEngine.reset(duration: timerDuration)
            _ = saveCurrentSessionSnapshot()
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
            cycleID = UUID()
            timerEngine.reset(duration: timerDuration)
        }
        _ = saveCurrentSessionSnapshot()
    }

    func takeBreak() {
        guard sessionPhase == .breakDue else { return }
        guard timerState.secondsRemaining > 0 else { return }

        sessionPhase = .breakRunning
        guard timerEngine.start() else {
            sessionPhase = .breakDue
            return
        }
        _ = saveCurrentSessionSnapshot()
    }

    func skipBreak() {
        guard sessionPhase.isBreak else { return }
        sessionPhase = .regularIdle
        turnsSinceBreak = 0
        cycleID = UUID()
        timerEngine.reset(duration: timerDuration)
        _ = saveCurrentSessionSnapshot()
    }

    func saveRoster() {
        _ = persistRosterThenSession(writeActiveFile: true)
    }

    func flushPersistence() {
        _ = persistRosterThenSession(writeActiveFile: true)
    }

    private func requestNotificationPermissionIfNeeded() {
        guard notificationsEnabled else { return }
        guard !hasRequestedNotificationPermission else { return }
        hasRequestedNotificationPermission = true
        notificationService.requestPermission()
    }

    func skipTurn() {
        guard canSkipTurn else { return }

        let skippedCycleID = cycleID
        sessionPhase = .regularIdle
        timerEngine.reset(duration: timerDuration)
        withDeferredRosterPersistence {
            roster.resolveRegularCycle(
                id: skippedCycleID,
                resolution: .skipped,
                advanceRoles: true
            )
        }
        cycleID = UUID()
        sessionPhase = .regularRunning
        guard timerEngine.start() else {
            sessionPhase = .regularIdle
            timerEngine.reset(duration: timerDuration)
            return
        }
        currentTip = Tip.random()
        guard persistRosterThenSession(writeActiveFile: true) else { return }
        accessibilityAnnouncer("Turn skipped. \(currentRoleSummary)")
        requestNotificationPermissionIfNeeded()
    }

    private var currentRoleSummary: String {
        guard let driver = roster.driver?.name else {
            return "No active participants."
        }
        guard let navigator = roster.navigator?.name else {
            return "Driver \(driver)."
        }
        return "Driver \(driver). Navigator \(navigator)."
    }

    private var breakDueAnnouncement: String {
        guard let driver = roster.driver?.name else {
            return "Break due."
        }
        guard let navigator = roster.navigator?.name else {
            return "Break due. Driver \(driver) is next."
        }
        return "Break due. Driver \(driver) is next. Navigator \(navigator)."
    }

    private static func accessibilityDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        var components: [String] = []
        if minutes > 0 {
            components.append("\(minutes) \(minutes == 1 ? "minute" : "minutes")")
        }
        if remainingSeconds > 0 || components.isEmpty {
            components.append(
                "\(remainingSeconds) \(remainingSeconds == 1 ? "second" : "seconds")"
            )
        }
        return components.joined(separator: ", ") + " remaining"
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
