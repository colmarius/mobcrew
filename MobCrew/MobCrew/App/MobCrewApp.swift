import SwiftUI

@main
struct MobCrewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    
    init() {
        // AppDelegate will be initialized by SwiftUI, we configure it in body
    }

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
                .onAppear {
                    configureAppDelegate()
                }
        }
        .onChange(of: appState.roster.activeMobsters) { _, _ in
            appState.saveRoster()
        }
        .onChange(of: appState.roster.inactiveMobsters) { _, _ in
            appState.saveRoster()
        }
        .onChange(of: appState.roster.nextDriverIndex) { _, _ in
            appState.saveRoster()
        }
        
        MenuBarExtra("MobCrew", systemImage: "stopwatch") {
            MenuBarView(
                driverName: appState.roster.driver?.name,
                navigatorName: appState.roster.navigator?.name,
                isRunning: appState.timerState.isRunning,
                onToggle: {
                    appState.toggleTimer()
                },
                onSkip: {
                    appState.skipTurn()
                }
            )
        }
        
        Settings {
            SettingsView(appState: appState)
        }
    }
    
    private func configureAppDelegate() {
        if appDelegate.appState == nil {
            appDelegate.appState = appState
            appDelegate.floatingTimerController = FloatingTimerController(appState: appState)
            appDelegate.floatingTimerController?.show()
        }
    }
}
