import Foundation

@Observable
final class AppState {
    let roster: Roster
    let timerState: TimerState
    let timerEngine: TimerEngine
    var timerDuration: Int {
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
    var turnsSinceBreak: Int = 0
    var isOnBreak: Bool = false
    var breakSecondsRemaining: Int = 0
    
    private let persistenceService: PersistenceService
    
    init(persistenceService: PersistenceService = PersistenceService()) {
        self.persistenceService = persistenceService
        
        let loadedRoster = persistenceService.loadRoster()
        let loadedDuration = persistenceService.loadTimerDuration() ?? 420 // 7 minutes default
        let loadedBreakInterval = persistenceService.loadBreakInterval() ?? 5
        let loadedBreakDuration = persistenceService.loadBreakDuration() ?? 300 // 5 minutes default
        
        self.roster = loadedRoster
        self.timerDuration = loadedDuration
        self.breakInterval = loadedBreakInterval
        self.breakDuration = loadedBreakDuration
        self.timerState = TimerState(
            secondsRemaining: loadedDuration,
            totalSeconds: loadedDuration
        )
        self.timerEngine = TimerEngine(state: timerState)
        
        setupBindings()
    }
    
    private func setupBindings() {
        timerEngine.configure(onComplete: { [weak self] in
            self?.handleTimerComplete()
        })
    }
    
    private func handleTimerComplete() {
        if isOnBreak {
            completeBreak()
        } else {
            roster.advanceTurn()
            turnsSinceBreak += 1
            
            if turnsSinceBreak >= breakInterval {
                triggerBreak()
            } else {
                timerEngine.reset(duration: timerDuration)
            }
        }
    }
    
    func triggerBreak() {
        isOnBreak = true
        breakSecondsRemaining = breakDuration
        timerEngine.reset(duration: breakDuration)
        timerEngine.start()
    }
    
    private func completeBreak() {
        isOnBreak = false
        turnsSinceBreak = 0
        breakSecondsRemaining = 0
        timerEngine.reset(duration: timerDuration)
    }
    
    func skipBreak() {
        timerEngine.stop()
        completeBreak()
    }
    
    func saveRoster() {
        persistenceService.saveRoster(roster)
    }
    
    func resetTimer() {
        timerEngine.reset(duration: timerDuration)
    }
    
    func toggleTimer() {
        timerEngine.toggle()
    }
    
    func skipTurn() {
        roster.advanceTurn()
        timerEngine.reset(duration: timerDuration)
        timerEngine.start()
    }
}
