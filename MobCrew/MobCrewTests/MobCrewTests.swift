import Testing
import AppKit
import Carbon
import Foundation
import ServiceManagement
@testable import MobCrew

@MainActor
@Suite("Floating Timer Controller Tests")
struct FloatingTimerControllerTests {
    @Test("show preserves a user-moved window position")
    func showPreservesMovedWindowPosition() {
        let suiteName = "com.mobcrew.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let appState = AppState(
            persistenceService: PersistenceService(userDefaults: defaults)
        )
        let controller = FloatingTimerController(appState: appState)
        controller.show()
        defer { controller.hide() }
        let window = controller.window!
        let movedOrigin = NSPoint(
            x: window.frame.origin.x - 100,
            y: window.frame.origin.y + 40
        )
        window.setFrameOrigin(movedOrigin)

        controller.hide()
        controller.show()

        #expect(window.frame.origin == movedOrigin)
    }
}

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
        let duplicate = GlobalHotkeyRegistrationState.failed(OSStatus(eventHotKeyExistsErr))
        let generic = GlobalHotkeyRegistrationState.failed(-50)

        #expect(duplicate.failureDescription?.contains("-9878") == true)
        #expect(duplicate.failureDescription?.contains("already registered") == true)
        #expect(generic.failureDescription?.contains("-50") == true)
        #expect(GlobalHotkeyRegistrationState.registered.failureDescription == nil)
    }
}

@MainActor
@Suite("Launch At Login Service Tests")
struct LaunchAtLoginServiceTests {
    @Test("every system status drives truthful registration intent")
    func statusPresentation() {
        let cases: [(SMAppService.Status, Bool)] = [
            (.notRegistered, false),
            (.enabled, true),
            (.requiresApproval, true),
            (.notFound, false)
        ]

        for (status, expectedIntent) in cases {
            let systemService = MockLaunchAtLoginSystemService(status: status)
            let service = LaunchAtLoginService(systemService: systemService)

            #expect(service.status == status)
            #expect(service.isRegistrationRequested == expectedIntent)
        }
    }

    @Test("operations refresh actual status instead of trusting the requested toggle")
    func operationsRefreshActualStatus() {
        let systemService = MockLaunchAtLoginSystemService(status: .notRegistered)
        let service = LaunchAtLoginService(systemService: systemService)
        systemService.statusAfterRegister = .requiresApproval

        service.setEnabled(true)

        #expect(systemService.registerCount == 1)
        #expect(service.status == .requiresApproval)
        #expect(service.isRegistrationRequested)

        systemService.statusAfterUnregister = .notRegistered
        service.setEnabled(false)

        #expect(systemService.unregisterCount == 1)
        #expect(service.status == .notRegistered)
        #expect(service.isRegistrationRequested == false)
    }

    @Test("thrown operation reports transient feedback then refreshes actual status")
    func operationFailureRefreshesStatus() {
        let systemService = MockLaunchAtLoginSystemService(status: .notRegistered)
        let service = LaunchAtLoginService(systemService: systemService)
        systemService.registerError = TestLaunchAtLoginError.failed
        systemService.status = .requiresApproval

        service.setEnabled(true)

        #expect(service.status == .requiresApproval)
        #expect(service.operationError != nil)
        service.dismissOperationError()
        #expect(service.operationError == nil)
    }

    @Test("refresh follows external status changes and recovery opens System Settings")
    func refreshAndOpenSettings() {
        let systemService = MockLaunchAtLoginSystemService(status: .notRegistered)
        var openCount = 0
        let service = LaunchAtLoginService(
            systemService: systemService,
            openSystemSettings: { openCount += 1 }
        )
        systemService.status = .enabled

        service.refreshStatus()
        service.openSystemSettings()

        #expect(service.status == .enabled)
        #expect(openCount == 1)
    }
}

private enum TestLaunchAtLoginError: Error {
    case failed
}

@MainActor
private final class MockLaunchAtLoginSystemService: LaunchAtLoginSystemServiceProtocol {
    var status: SMAppService.Status
    var statusAfterRegister: SMAppService.Status?
    var statusAfterUnregister: SMAppService.Status?
    var registerError: Error?
    var unregisterError: Error?
    var registerCount = 0
    var unregisterCount = 0

    init(status: SMAppService.Status) {
        self.status = status
    }

    func register() throws {
        registerCount += 1
        if let registerError { throw registerError }
        if let statusAfterRegister { status = statusAfterRegister }
    }

    func unregister() throws {
        unregisterCount += 1
        if let unregisterError { throw unregisterError }
        if let statusAfterUnregister { status = statusAfterUnregister }
    }
}
