import AppKit
import SwiftUI

final class FloatingTimerController {
    private var window: FloatingTimerWindow?
    private var hostingView: NSHostingView<AnyView>?
    
    private let timerEngine: TimerEngine
    private let roster: Roster
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    init(timerEngine: TimerEngine, roster: Roster) {
        self.timerEngine = timerEngine
        self.roster = roster
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
            displayTime: timerEngine.state.displayTime,
            driverName: roster.driver?.name,
            navigatorName: roster.navigator?.name,
            isRunning: timerEngine.isRunning,
            onToggle: { [weak self] in
                self?.timerEngine.toggle()
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
            displayTime: timerEngine.state.displayTime,
            driverName: roster.driver?.name,
            navigatorName: roster.navigator?.name,
            isRunning: timerEngine.isRunning,
            onToggle: { [weak self] in
                self?.timerEngine.toggle()
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
