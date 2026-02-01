import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingTimerController: FloatingTimerController?
    var appState: AppState?
    private var hasShownAccessibilityAlert = false
    
    private static let hasRequestedPermissionKey = "hasRequestedAccessibilityPermission"
    
    private var hasRequestedPermissionBefore: Bool {
        get { UserDefaults.standard.bool(forKey: Self.hasRequestedPermissionKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.hasRequestedPermissionKey) }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
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
        
        if hasRequestedPermissionBefore {
            alert.informativeText = """
            MobCrew needs Accessibility permission to use the global hotkey (⌘⇧L).
            
            To grant permission:
            1. Click "Open System Settings" below
            2. Click the + button at the bottom of the list
            3. Navigate to and select MobCrew
            4. Enable the toggle next to MobCrew
            
            If MobCrew is already in the list but disabled, enable its toggle.
            """
        } else {
            alert.informativeText = """
            MobCrew needs Accessibility permission to use the global hotkey (⌘⇧L) for toggling the floating timer.
            
            You'll be prompted to grant access. If the app doesn't appear in the list automatically, you may need to add it manually using the + button.
            """
        }
        
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Not Now")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            hasRequestedPermissionBefore = true
            GlobalHotkeyService.requestAccessibilityPermission()
            startPollingForPermission()
        }
    }
    
    private func startPollingForPermission() {
        GlobalHotkeyService.shared.startPollingForPermission { [weak self] in
            self?.onAccessibilityPermissionGranted()
        }
    }
    
    private func onAccessibilityPermissionGranted() {
        registerGlobalHotkey()
        showPermissionGrantedNotification()
    }
    
    private func showPermissionGrantedNotification() {
        let alert = NSAlert()
        alert.messageText = "Global Hotkey Enabled"
        alert.informativeText = "Accessibility permission granted. You can now use ⌘⇧L to toggle the floating timer."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
