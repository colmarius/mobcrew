import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingTimerController: FloatingTimerController?
    var appState: AppState?
    private var hasShownAccessibilityAlert = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let appState = appState {
            floatingTimerController = FloatingTimerController(appState: appState)
            floatingTimerController?.show()
        }
        
        checkAccessibilityPermission()
        registerGlobalHotkey()
    }
    
    private func registerGlobalHotkey() {
        GlobalHotkeyService.shared.register { [weak self] in
            DispatchQueue.main.async {
                self?.toggleFloatingTimer()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        floatingTimerController?.hide()
        GlobalHotkeyService.shared.unregister()
    }
    
    func toggleFloatingTimer() {
        floatingTimerController?.toggle()
    }
    
    private func checkAccessibilityPermission() {
        if GlobalHotkeyService.hasAccessibilityPermission {
            return
        }
        
        guard !hasShownAccessibilityAlert else { return }
        hasShownAccessibilityAlert = true
        
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "MobCrew needs Accessibility permission to use the global hotkey (Cmd+Shift+L) for toggling the floating timer. Would you like to open System Settings?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Not Now")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            GlobalHotkeyService.requestAccessibilityPermission()
        }
    }
}
