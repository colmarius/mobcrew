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
            MenuBarView(appState: appState)
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
