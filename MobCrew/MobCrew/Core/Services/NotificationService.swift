import Foundation
import UserNotifications

protocol NotificationCenterProtocol {
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping @Sendable (Bool, Error?) -> Void)
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?)
}

extension UNUserNotificationCenter: NotificationCenterProtocol {}

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    
    private let notificationCenter: NotificationCenterProtocol
    private var permissionRequested = false
    
    init(notificationCenter: NotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.notificationCenter = notificationCenter
    }
    
    func requestPermission(completion: (@Sendable (Bool) -> Void)? = nil) {
        guard !permissionRequested else {
            completion?(true)
            return
        }
        
        permissionRequested = true
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            completion?(granted)
        }
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
    
    func sendBreakStarted(duration: Int) {
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
}
