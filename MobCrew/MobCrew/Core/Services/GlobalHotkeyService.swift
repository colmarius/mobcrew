import Foundation
import Carbon
import AppKit

final class GlobalHotkeyService {
    static let shared = GlobalHotkeyService()
    
    private var hotkeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (() -> Void)?
    
    private init() {}
    
    deinit {
        unregister()
    }
    
    /// Registers Cmd+Shift+L as a global hotkey
    /// - Parameter callback: Called when the hotkey is pressed
    /// - Returns: true if registration succeeded
    @discardableResult
    func register(callback: @escaping () -> Void) -> Bool {
        guard hotkeyRef == nil else { return true }
        
        self.callback = callback
        
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let handlerResult = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                let service = Unmanaged<GlobalHotkeyService>.fromOpaque(userData).takeUnretainedValue()
                service.callback?()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        
        guard handlerResult == noErr else {
            print("Failed to install event handler: \(handlerResult)")
            return false
        }
        
        // Cmd+Shift+L: modifiers = cmdKey + shiftKey, keyCode = 37 (L)
        var hotkeyID = EventHotKeyID(
            signature: OSType(0x4D4F4243),  // "MOBC" for MobCrew
            id: 1
        )
        
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = 37  // 'L' key
        
        let registerResult = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
        
        if registerResult != noErr {
            print("Failed to register hotkey: \(registerResult)")
            removeEventHandler()
            return false
        }
        
        return true
    }
    
    func unregister() {
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
        removeEventHandler()
        callback = nil
    }
    
    private func removeEventHandler() {
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    /// Checks if accessibility permission is granted (required for global hotkeys to work reliably)
    static var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }
    
    /// Prompts user for accessibility permission and opens System Settings
    static func requestAccessibilityPermission() {
        // This triggers the system prompt which adds the app to the list
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        
        // Also open System Settings directly for convenience
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
