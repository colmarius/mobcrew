import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingTimerController: FloatingTimerController?
    var appState: AppState?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        registerGlobalHotkey()
    }
    
    private func registerGlobalHotkey() {
        GlobalHotkeyService.shared.register { [weak self] in
            self?.toggleFloatingTimer()
        }
    }

    func applicationWillResignActive(_ notification: Notification) {
        appState?.flushPersistence()
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState?.flushPersistence()
        floatingTimerController?.hide()
        GlobalHotkeyService.shared.unregister()
    }
    
    func toggleFloatingTimer() {
        floatingTimerController?.toggle()
    }
}
