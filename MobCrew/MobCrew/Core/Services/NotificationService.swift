import Foundation
import AppKit
import Combine
import UserNotifications

@MainActor
protocol NotificationCenterProtocol {
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping @Sendable (Bool, Error?) -> Void)
    func currentAuthorizationStatus() async -> UNAuthorizationStatus
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?)
}

extension UNUserNotificationCenter: NotificationCenterProtocol {
    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }
}

@MainActor
protocol NotificationServiceProtocol {
    func requestPermission()
    func sendTimerComplete(driver: String, navigator: String)
    func sendBreakDue(duration: Int)
    func sendBreakComplete()
}

@MainActor
final class NotificationService: ObservableObject, NotificationServiceProtocol {
    static let shared = NotificationService()

    private let notificationCenter: NotificationCenterProtocol
    private let systemSettingsOpener: () -> Void
    private var permissionRequestInFlight = false
    private var authorizationRefreshGeneration = 0

    @Published private(set) var authorizationStatus: UNAuthorizationStatus?
    @Published private(set) var operationError: String?

    init(
        notificationCenter: NotificationCenterProtocol = UNUserNotificationCenter.current(),
        openSystemSettings: @escaping () -> Void = NotificationService.openSystemNotificationSettings
    ) {
        self.notificationCenter = notificationCenter
        self.systemSettingsOpener = openSystemSettings
    }

    func requestPermission() {
        Task { [weak self] in
            await self?.requestPermissionIfNeeded()
        }
    }

    func requestPermissionIfNeeded() async {
        guard !permissionRequestInFlight else { return }
        permissionRequestInFlight = true
        defer { permissionRequestInFlight = false }

        let (currentStatus, isLatestRefresh) = await fetchAuthorizationStatus()
        guard isLatestRefresh, currentStatus == .notDetermined else { return }

        let errorDescription: String? = await withCheckedContinuation { continuation in
            notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
                continuation.resume(returning: error?.localizedDescription)
            }
        }
        operationError = errorDescription
        await refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() async {
        _ = await fetchAuthorizationStatus()
    }

    func openSystemSettings() {
        systemSettingsOpener()
    }

    func dismissOperationError() {
        operationError = nil
    }

    private func fetchAuthorizationStatus() async -> (status: UNAuthorizationStatus, isLatest: Bool) {
        authorizationRefreshGeneration += 1
        let generation = authorizationRefreshGeneration
        let status = await notificationCenter.currentAuthorizationStatus()
        guard generation == authorizationRefreshGeneration else {
            return (status, false)
        }
        authorizationStatus = status
        return (status, true)
    }
    
    func sendTimerComplete(driver: String, navigator: String) {
        let content = UNMutableNotificationContent()
        content.title = "Time's Up!"
        content.body = "Driver: \(driver) → Navigator: \(navigator)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to send timer notification: \(error)")
            }
        }
    }
    
    func sendBreakDue(duration: Int) {
        let minutes = duration / 60
        let content = UNMutableNotificationContent()
        content.title = "Break Time!"
        content.body = "Take a \(minutes) minute break"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to send break notification: \(error)")
            }
        }
    }

    func sendBreakComplete() {
        let content = UNMutableNotificationContent()
        content.title = "Break Complete"
        content.body = "Ready for the next turn."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to send break completion notification: \(error)")
            }
        }
    }

    private static func openSystemNotificationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
