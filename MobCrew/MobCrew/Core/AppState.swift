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
    
    private let persistenceService: PersistenceService
    
    init(persistenceService: PersistenceService = PersistenceService()) {
        self.persistenceService = persistenceService
        
        let loadedRoster = persistenceService.loadRoster()
        let loadedDuration = persistenceService.loadTimerDuration() ?? 420 // 7 minutes default
        
        self.roster = loadedRoster
        self.timerDuration = loadedDuration
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
        roster.advanceTurn()
        timerEngine.reset(duration: timerDuration)
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
