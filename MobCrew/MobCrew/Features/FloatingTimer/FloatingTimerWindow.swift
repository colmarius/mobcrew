import AppKit

final class FloatingTimerWindow: NSPanel {
    
    init(contentRect: NSRect = NSRect(x: 0, y: 0, width: 150, height: 100)) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        configureWindow()
    }
    
    private func configureWindow() {
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        isMovableByWindowBackground = true
        
        hidesOnDeactivate = false
    }
    
    override var canBecomeKey: Bool {
        true
    }
    
    override var canBecomeMain: Bool {
        false
    }
}
