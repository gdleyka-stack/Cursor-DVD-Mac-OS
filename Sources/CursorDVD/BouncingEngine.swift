import SwiftUI
import AppKit
import Combine

public class BouncingEngine: ObservableObject {
    @Published public var cursorColor: Color = .red
    @Published public var cursorStyle: ScreensaverStyle = .hybrid
    
    private var window: OverlayWindow?
    private var timer: Timer?
    
    // Animation state
    private var position: CGPoint = .zero
    private var velocity: CGVector = CGVector(dx: 4.0, dy: 4.0)
    private let size = CGSize(width: 120, height: 120)
    
    // Screen bounds
    private var screenFrame: NSRect = .zero
    
    // Activity detection
    private var initialMouseLocation: NSPoint = .zero
    private var checkActivityTimer: Timer?
    
    // Callback to notify main application that we stopped
    public var onStop: (() -> Void)?
    
    private let availableColors: [Color] = [
        .red, .green, .blue, .yellow, .orange, .purple, .pink, .cyan, .mint
    ]
    
    public init() {}
    
    public func start(style: ScreensaverStyle) {
        self.cursorStyle = style
        
        // 1. Get the screen where the mouse cursor currently is
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens[0]
        
        self.screenFrame = screen.frame
        self.initialMouseLocation = mouseLocation
        
        // 2. Position the bouncing cursor starting at the user's current mouse position (scaled to screen)
        // Ensure the initial position is within bounds
        let startX = max(0, min(mouseLocation.x - screenFrame.origin.x - size.width/2, screenFrame.size.width - size.width))
        let startY = max(0, min(mouseLocation.y - screenFrame.origin.y - size.height/2, screenFrame.size.height - size.height))
        self.position = CGPoint(x: startX, y: startY)
        
        // Set a random initial direction
        let angle = Double.random(in: 0.1...0.4) * Double.pi // angles that avoid perfect horizontal/vertical
        let speed: Double = 6.0
        let directionX = Bool.random() ? 1.0 : -1.0
        let directionY = Bool.random() ? 1.0 : -1.0
        self.velocity = CGVector(dx: cos(angle) * speed * directionX, dy: sin(angle) * speed * directionY)
        
        // Choose a random starting color
        self.cursorColor = availableColors.randomElement() ?? .red
        
        // 3. Create full-screen transparent window
        let overlay = OverlayWindow(screen: screen)
        
        // 4. Create host view for SwiftUI
        let contentView = NSHostingView(rootView: EngineOverlayView(engine: self))
        contentView.frame = NSRect(origin: .zero, size: screenFrame.size)
        overlay.contentView = contentView
        
        self.window = overlay
        
        // 5. Hide system cursor
        CGDisplayHideCursor(kCGNullDirectDisplay)
        
        // 6. Show the window
        overlay.makeKeyAndOrderFront(nil)
        overlay.orderFrontRegardless()
        
        // 7. Start animation loop (approx 60 FPS)
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updatePosition()
        }
        
        // 8. Start activity polling timer (every 100ms)
        self.checkActivityTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkUserActivity()
        }
    }
    
    public func stop() {
        // 1. Show system cursor again
        CGDisplayShowCursor(kCGNullDirectDisplay)
        
        // 2. Stop timers
        timer?.invalidate()
        timer = nil
        checkActivityTimer?.invalidate()
        checkActivityTimer = nil
        
        // 3. Close window
        window?.close()
        window = nil
        
        // 4. Trigger callback
        onStop?()
    }
    
    private func updatePosition() {
        var newX = position.x + velocity.dx
        var newY = position.y + velocity.dy
        
        let maxX = screenFrame.size.width - size.width
        let maxY = screenFrame.size.height - size.height
        
        var bounced = false
        
        // Bounce Left / Right
        if newX <= 0 {
            newX = 0
            velocity.dx = -velocity.dx
            bounced = true
        } else if newX >= maxX {
            newX = maxX
            velocity.dx = -velocity.dx
            bounced = true
        }
        
        // Bounce Bottom / Top
        if newY <= 0 {
            newY = 0
            velocity.dy = -velocity.dy
            bounced = true
        } else if newY >= maxY {
            newY = maxY
            velocity.dy = -velocity.dy
            bounced = true
        }
        
        self.position = CGPoint(x: newX, y: newY)
        
        if bounced {
            changeColor()
        }
    }
    
    private func changeColor() {
        let otherColors = availableColors.filter { $0 != cursorColor }
        if let nextColor = otherColors.randomElement() {
            self.cursorColor = nextColor
        }
    }
    
    private func checkUserActivity() {
        // Method A: Check system-wide idle time
        let idleTime = IdleMonitor.getSystemIdleTime()
        
        // Method B: Check mouse cursor displacement (threshold: 5 pixels)
        let currentMouse = NSEvent.mouseLocation
        let dx = currentMouse.x - initialMouseLocation.x
        let dy = currentMouse.y - initialMouseLocation.y
        let distance = sqrt(dx*dx + dy*dy)
        
        // If system is no longer idle (time since last event < 0.5s), or mouse moved
        if idleTime < 0.5 || distance > 5.0 {
            self.stop()
        }
    }
    
    // View interface
    public var cursorPosition: CGPoint {
        position
    }
    
    public var cursorSize: CGSize {
        size
    }
}

// SwiftUI view wrapper for the bouncing engine content
struct EngineOverlayView: View {
    @ObservedObject var engine: BouncingEngine
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Fill background with near-black transparent layer to slightly dim other windows (optional, lets make it fully transparent first)
            Color.clear
            
            CursorView(color: engine.cursorColor, style: engine.cursorStyle)
                .frame(width: engine.cursorSize.width, height: engine.cursorSize.height)
                .position(x: engine.cursorPosition.x + engine.cursorSize.width / 2,
                          y: engine.cursorSize.height / 2 + engine.cursorPosition.y) // Adjusting coordinate origin difference (SwiftUI postion uses center, we track bottom-left)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.01)) // Minimal opacity needed to intercept window bounds or capture updates correctly
    }
}
