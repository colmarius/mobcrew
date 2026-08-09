import Foundation
import Carbon
import Combine

struct GlobalHotkeyDefinition: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32
    let displayName: String
    let actionDescription: String
}

enum GlobalHotkeyRegistrationState: Equatable {
    case notRegistered
    case registered
    case failed(OSStatus)

    var failureDescription: String? {
        guard case .failed(let status) = self else { return nil }
        if status == eventHotKeyExistsErr {
            return "Carbon reports that this shortcut is already registered (error \(status))."
        }
        return "MobCrew could not register the global shortcut (error \(status))."
    }
}

@MainActor
final class GlobalHotkeyService: ObservableObject {
    static let shared = GlobalHotkeyService()
    static let shortcut = GlobalHotkeyDefinition(
        keyCode: UInt32(kVK_ANSI_L),
        modifiers: UInt32(cmdKey | shiftKey),
        displayName: "⌘⇧L",
        actionDescription: "Toggle floating timer"
    )
    
    private var hotkeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (@MainActor () -> Void)?
    @Published private(set) var registrationState: GlobalHotkeyRegistrationState = .notRegistered
    
    private init() {}
    
    isolated deinit {
        unregister()
    }
    
    /// Registers the fixed global shortcut.
    /// - Parameter callback: Called when the hotkey is pressed
    /// - Returns: true if registration succeeded
    @discardableResult
    func register(callback: @escaping @MainActor () -> Void) -> Bool {
        guard hotkeyRef == nil else {
            registrationState = .registered
            return true
        }
        
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
                MainActor.assumeIsolated {
                    service.callback?()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        
        guard handlerResult == noErr else {
            registrationState = .failed(handlerResult)
            print("Failed to install event handler: \(handlerResult)")
            return false
        }
        
        let hotkeyID = EventHotKeyID(
            signature: OSType(0x4D4F4243),  // "MOBC" for MobCrew
            id: 1
        )
        let shortcut = Self.shortcut
        
        let registerResult = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
        
        if registerResult != noErr {
            registrationState = .failed(registerResult)
            print("Failed to register hotkey: \(registerResult)")
            removeEventHandler()
            return false
        }
        
        registrationState = .registered
        return true
    }

    @discardableResult
    func retryRegistration() -> Bool {
        guard let callback else { return false }
        return register(callback: callback)
    }
    
    func unregister() {
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
        removeEventHandler()
        callback = nil
        registrationState = .notRegistered
    }
    
    private func removeEventHandler() {
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
}
