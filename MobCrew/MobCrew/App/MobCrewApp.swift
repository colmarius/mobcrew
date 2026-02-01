import SwiftUI

@main
struct MobCrewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var roster = Roster()
    @State private var timerState = TimerState()

    var body: some Scene {
        WindowGroup {
            ContentView()
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
