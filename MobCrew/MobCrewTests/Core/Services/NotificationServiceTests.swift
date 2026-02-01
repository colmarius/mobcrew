import Testing
import Foundation
import UserNotifications
@testable import MobCrew

@Suite("NotificationService Tests")
struct NotificationServiceTests {

    @Test("timer complete notification has correct content")
    func timerCompleteNotificationContent() {
        let mockCenter = MockNotificationCenter()
        let service = NotificationService(notificationCenter: mockCenter)
        
        service.sendTimerComplete(driver: "Alice", navigator: "Bob")
        
        #expect(mockCenter.addedRequests.count == 1)
        let request = mockCenter.addedRequests.first!
        #expect(request.content.title == "Time's Up!")
        #expect(request.content.body == "Driver: Alice → Navigator: Bob")
        #expect(request.content.sound == .default)
    }
    
    @Test("break started notification has correct content")
    func breakStartedNotificationContent() {
        let mockCenter = MockNotificationCenter()
        let service = NotificationService(notificationCenter: mockCenter)
        
        service.sendBreakStarted(duration: 300)
        
        #expect(mockCenter.addedRequests.count == 1)
        let request = mockCenter.addedRequests.first!
        #expect(request.content.title == "Break Time!")
        #expect(request.content.body == "Take a 5 minute break")
        #expect(request.content.sound == .default)
    }
    
    @Test("break started notification formats minutes correctly")
    func breakStartedNotificationMinutesFormat() {
        let mockCenter = MockNotificationCenter()
        let service = NotificationService(notificationCenter: mockCenter)
        
        service.sendBreakStarted(duration: 600)
        
        let request = mockCenter.addedRequests.first!
        #expect(request.content.body == "Take a 10 minute break")
    }
    
    @Test("request permission only prompts once")
    func requestPermissionOnlyOnce() {
        let mockCenter = MockNotificationCenter()
        let service = NotificationService(notificationCenter: mockCenter)
        
        service.requestPermission()
        service.requestPermission()
        service.requestPermission()
        
        #expect(mockCenter.authorizationRequestCount == 1)
    }
}

final class MockNotificationCenter: NotificationCenterProtocol {
    var addedRequests: [UNNotificationRequest] = []
    var authorizationRequestCount = 0
    var authorizationGranted = true
    
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
        addedRequests.append(request)
        completionHandler?(nil)
    }
    
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
        authorizationRequestCount += 1
        completionHandler(authorizationGranted, nil)
    }
}
