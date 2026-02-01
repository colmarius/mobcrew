import SwiftUI

@main
struct MobCrewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var roster: Roster
    @State private var timerState: TimerState
    @State private var timerDuration: Int
    
    private let persistenceService = PersistenceService()
    
    init() {
        let service = PersistenceService()
        let loadedRoster = service.loadRoster()
        let loadedDuration = service.loadTimerDuration() ?? 420 // 7 minutes default
        
        _roster = State(initialValue: loadedRoster)
        _timerState = State(initialValue: TimerState(
            secondsRemaining: loadedDuration,
            totalSeconds: loadedDuration
        ))
        _timerDuration = State(initialValue: loadedDuration)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: roster.activeMobsters) { _, _ in
            persistenceService.saveRoster(roster)
        }
        .onChange(of: roster.inactiveMobsters) { _, _ in
            persistenceService.saveRoster(roster)
        }
        .onChange(of: roster.nextDriverIndex) { _, _ in
            persistenceService.saveRoster(roster)
        }
        .onChange(of: timerDuration) { _, newValue in
            persistenceService.saveTimerDuration(newValue)
        }
        
        MenuBarExtra("MobCrew", systemImage: "person.3.fill") {
            MenuBarView(
                driverName: roster.driver?.name,
                navigatorName: roster.navigator?.name,
                isRunning: timerState.isRunning,
                onToggle: {
                    timerState.isRunning.toggle()
                },
                onSkip: {
                    roster.advanceTurn()
                },
                onOpenSettings: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            )
        }
    }
}
