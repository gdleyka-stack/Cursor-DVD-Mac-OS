import AppKit

public class CursorAreaView: NSView {
    public var currentCursor: NSCursor? {
        didSet {
            // Force OS to update the cursor shape over this view
            self.window?.invalidateCursorRects(for: self)
        }
    }
    
    public override func resetCursorRects() {
        if let cursor = currentCursor {
            addCursorRect(self.bounds, cursor: cursor)
        }
    }
}

public class OverlayWindow: NSWindow {
    public let cursorView: CursorAreaView
    
    public init(screen: NSScreen) {
        let view = CursorAreaView(frame: NSRect(origin: .zero, size: screen.frame.size))
        self.cursorView = view
        
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        self.ignoresMouseEvents = false // Must capture mouse to apply cursor rects
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.setFrame(screen.frame, display: true)
        self.contentView = view
    }
    
    public override var canBecomeKey: Bool {
        return true
    }
    
    public override var canBecomeMain: Bool {
        return true
    }
    
    public override func sendEvent(_ event: NSEvent) {
        // Any user interaction (click, keypress) triggers dismiss
        if event.type == .leftMouseDown || event.type == .rightMouseDown || event.type == .otherMouseDown || event.type == .keyDown {
            NotificationCenter.default.post(name: NSNotification.Name("UserActivityDetected"), object: nil)
        }
        super.sendEvent(event)
    }
}
