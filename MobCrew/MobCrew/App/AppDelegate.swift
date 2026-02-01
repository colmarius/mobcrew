import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingTimerController: FloatingTimerController?
    var appState: AppState?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let appState = appState {
            floatingTimerController = FloatingTimerController(appState: appState)
            floatingTimerController?.show()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        floatingTimerController?.hide()
    }
    
    func toggleFloatingTimer() {
        floatingTimerController?.toggle()
    }
}
