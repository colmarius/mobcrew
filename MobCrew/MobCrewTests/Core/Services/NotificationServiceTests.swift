import Testing
import Foundation
import UserNotifications
@testable import MobCrew

@MainActor
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
    
    @Test("break due notification has correct content")
    func breakDueNotificationContent() {
        let mockCenter = MockNotificationCenter()
        let service = NotificationService(notificationCenter: mockCenter)
        
        service.sendBreakDue(duration: 300)
        
        #expect(mockCenter.addedRequests.count == 1)
        let request = mockCenter.addedRequests.first!
        #expect(request.content.title == "Break Time!")
        #expect(request.content.body == "Take a 5 minute break")
        #expect(request.content.sound == .default)
    }
    
    @Test("break due notification formats minutes correctly")
    func breakDueNotificationMinutesFormat() {
        let mockCenter = MockNotificationCenter()
        let service = NotificationService(notificationCenter: mockCenter)
        
        service.sendBreakDue(duration: 600)
        
        let request = mockCenter.addedRequests.first!
        #expect(request.content.body == "Take a 10 minute break")
    }

    @Test("break complete notification has fixed content")
    func breakCompleteNotificationContent() {
        let mockCenter = MockNotificationCenter()
        let service = NotificationService(notificationCenter: mockCenter)

        service.sendBreakComplete()

        #expect(mockCenter.addedRequests.count == 1)
        let request = mockCenter.addedRequests.first!
        #expect(request.content.title == "Break Complete")
        #expect(request.content.body == "Ready for the next turn.")
        #expect(request.content.sound == .default)
    }
    
    @Test("request permission only prompts once")
    func requestPermissionOnlyOnce() async {
        let mockCenter = MockNotificationCenter()
        let service = NotificationService(notificationCenter: mockCenter)
        
        await service.requestPermissionIfNeeded()
        await service.requestPermissionIfNeeded()
        await service.requestPermissionIfNeeded()
        
        #expect(mockCenter.authorizationRequestCount == 1)
        #expect(service.authorizationStatus == .authorized)
    }

    @Test("known system status never requests authorization again", arguments: [
        UNAuthorizationStatus.denied,
        .authorized,
        .provisional,
        .ephemeral
    ])
    func knownStatusDoesNotRequestPermission(status: UNAuthorizationStatus) async {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = status
        let service = NotificationService(notificationCenter: mockCenter)

        await service.requestPermissionIfNeeded()

        #expect(mockCenter.authorizationRequestCount == 0)
        #expect(service.authorizationStatus == status)
    }

    @Test("failed request reports transient feedback and preserves refreshed status")
    func requestFailureRefreshesStatus() async {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationError = TestNotificationError.failed
        let service = NotificationService(notificationCenter: mockCenter)

        await service.requestPermissionIfNeeded()

        #expect(service.authorizationStatus == .notDetermined)
        #expect(service.operationError != nil)
        service.dismissOperationError()
        #expect(service.operationError == nil)
    }

    @Test("refresh exposes every system authorization status")
    func refreshAuthorizationStatus() async {
        let mockCenter = MockNotificationCenter()
        let service = NotificationService(notificationCenter: mockCenter)

        #expect(service.authorizationStatus == nil)

        for status in [
            UNAuthorizationStatus.notDetermined,
            .denied,
            .authorized,
            .provisional,
            .ephemeral
        ] {
            mockCenter.authorizationStatus = status

            await service.refreshAuthorizationStatus()

            #expect(service.authorizationStatus == status)
        }
    }

    @Test("a superseded permission read neither overwrites status nor requests")
    func supersededPermissionRead() async {
        let mockCenter = MockNotificationCenter()
        mockCenter.suspendStatusRequests = true
        let service = NotificationService(notificationCenter: mockCenter)

        let permissionTask = Task { await service.requestPermissionIfNeeded() }
        while mockCenter.pendingStatusRequestCount < 1 {
            await Task.yield()
        }
        let refreshTask = Task { await service.refreshAuthorizationStatus() }
        while mockCenter.pendingStatusRequestCount < 2 {
            await Task.yield()
        }

        mockCenter.completeStatusRequest(at: 1, with: .denied)
        await refreshTask.value
        mockCenter.completeStatusRequest(at: 0, with: .notDetermined)
        await permissionTask.value

        #expect(service.authorizationStatus == .denied)
        #expect(mockCenter.authorizationRequestCount == 0)
    }

    @Test("notification settings recovery action uses the injected opener")
    func opensNotificationSettings() {
        var openCount = 0
        let service = NotificationService(
            notificationCenter: MockNotificationCenter(),
            openSystemSettings: { openCount += 1 }
        )

        service.openSystemSettings()

        #expect(openCount == 1)
    }
}

@MainActor
final class MockNotificationCenter: NotificationCenterProtocol {
    var addedRequests: [UNNotificationRequest] = []
    var authorizationRequestCount = 0
    var authorizationGranted = true
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var authorizationError: Error?
    var suspendStatusRequests = false
    private var statusRequestContinuations: [CheckedContinuation<UNAuthorizationStatus, Never>] = []

    var pendingStatusRequestCount: Int {
        statusRequestContinuations.count
    }
    
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?) {
        addedRequests.append(request)
        completionHandler?(nil)
    }
    
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping @Sendable (Bool, Error?) -> Void) {
        authorizationRequestCount += 1
        if let authorizationError {
            completionHandler(false, authorizationError)
            return
        }
        authorizationStatus = authorizationGranted ? .authorized : .denied
        completionHandler(authorizationGranted, nil)
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        guard suspendStatusRequests else { return authorizationStatus }
        return await withCheckedContinuation { continuation in
            statusRequestContinuations.append(continuation)
        }
    }

    func completeStatusRequest(at index: Int, with status: UNAuthorizationStatus) {
        let continuation = statusRequestContinuations.remove(at: index)
        continuation.resume(returning: status)
    }
}

private enum TestNotificationError: Error {
    case failed
}
