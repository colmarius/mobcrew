import AppKit
import SwiftUI

final class FloatingTimerController {
    private var window: FloatingTimerWindow?
    private var hostingView: NSHostingView<AnyView>?
    
    private let appState: AppState
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func show() {
        if window == nil {
            createWindow()
        }
        positionWindow()
        window?.orderFront(nil)
    }
    
    func hide() {
        window?.orderOut(nil)
    }
    
    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    private func createWindow() {
        let window = FloatingTimerWindow()
        
        let view = FloatingTimerView(
            displayTime: appState.timerState.displayTime,
            driverName: appState.roster.driver?.name,
            navigatorName: appState.roster.navigator?.name,
            isRunning: appState.timerState.isRunning,
            onToggle: { [weak self] in
                self?.appState.toggleTimer()
            }
        )
        
        let hostingView = NSHostingView(rootView: AnyView(view))
        hostingView.frame = window.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        
        window.contentView?.addSubview(hostingView)
        
        self.window = window
        self.hostingView = hostingView
    }
    
    func updateView() {
        guard let hostingView = hostingView else { return }
        
        let view = FloatingTimerView(
            displayTime: appState.timerState.displayTime,
            driverName: appState.roster.driver?.name,
            navigatorName: appState.roster.navigator?.name,
            isRunning: appState.timerState.isRunning,
            onToggle: { [weak self] in
                self?.appState.toggleTimer()
            }
        )
        
        hostingView.rootView = AnyView(view)
    }
    
    private func positionWindow() {
        guard let window = window,
              let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        let padding: CGFloat = 20
        
        let x = screenFrame.maxX - windowSize.width - padding
        let y = screenFrame.minY + padding
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
