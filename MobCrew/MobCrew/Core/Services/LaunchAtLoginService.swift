import Foundation
import ServiceManagement
import Combine

@MainActor
protocol LaunchAtLoginSystemServiceProtocol: AnyObject {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

extension SMAppService: LaunchAtLoginSystemServiceProtocol {}

@MainActor
final class LaunchAtLoginService: ObservableObject {
    static let shared = LaunchAtLoginService()

    @Published private(set) var status: SMAppService.Status
    @Published private(set) var operationError: String?

    private let systemService: LaunchAtLoginSystemServiceProtocol
    private let systemSettingsOpener: () -> Void

    var isRegistrationRequested: Bool {
        switch status {
        case .enabled, .requiresApproval:
            true
        case .notRegistered, .notFound:
            false
        @unknown default:
            false
        }
    }

    init(
        systemService: LaunchAtLoginSystemServiceProtocol = SMAppService.mainApp,
        openSystemSettings: @escaping () -> Void = SMAppService.openSystemSettingsLoginItems
    ) {
        self.systemService = systemService
        self.systemSettingsOpener = openSystemSettings
        self.status = systemService.status
    }

    func setEnabled(_ enabled: Bool) {
        operationError = nil
        do {
            if enabled {
                try systemService.register()
            } else {
                try systemService.unregister()
            }
        } catch {
            operationError = error.localizedDescription
        }
        refreshStatus()
    }

    func refreshStatus() {
        status = systemService.status
    }

    func openSystemSettings() {
        systemSettingsOpener()
    }

    func dismissOperationError() {
        operationError = nil
    }
}
