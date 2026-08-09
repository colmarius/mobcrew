import Testing
import Carbon
@testable import MobCrew

@MainActor
@Suite("Global Hotkey Service Tests")
struct GlobalHotkeyServiceTests {
    @Test("fixed shortcut defines the registered chord and action")
    func fixedShortcutDefinition() {
        let shortcut = GlobalHotkeyService.shortcut

        #expect(shortcut.keyCode == UInt32(kVK_ANSI_L))
        #expect(shortcut.modifiers == UInt32(cmdKey | shiftKey))
        #expect(shortcut.displayName == "⌘⇧L")
        #expect(shortcut.actionDescription == "Toggle floating timer")
    }

    @Test("registration failures expose their Carbon status")
    func registrationFailureDescription() {
        let duplicate = GlobalHotkeyRegistrationState.failed(eventHotKeyExistsErr)
        let generic = GlobalHotkeyRegistrationState.failed(-50)

        #expect(duplicate.failureDescription?.contains("-9878") == true)
        #expect(duplicate.failureDescription?.contains("already registered") == true)
        #expect(generic.failureDescription?.contains("-50") == true)
        #expect(GlobalHotkeyRegistrationState.registered.failureDescription == nil)
    }
}
