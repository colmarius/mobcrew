import SwiftUI

@main
struct MobCrewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
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
        
        MenuBarExtra("MobCrew", systemImage: "person.3.fill") {
            MenuBarView(
                driverName: appState.roster.driver?.name,
                navigatorName: appState.roster.navigator?.name,
                isRunning: appState.timerState.isRunning,
                onToggle: {
                    appState.toggleTimer()
                },
                onSkip: {
                    appState.skipTurn()
                },
                onOpenSettings: {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            )
        }
    }
}
