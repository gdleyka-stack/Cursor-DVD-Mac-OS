import AppKit
import SwiftUI
import Combine

public class BouncingEngine: ObservableObject {
    @Published public var cursorColor: Color = .red
    @Published public var cursorStyle: ScreensaverStyle = .hybrid
    
    private var window: OverlayWindow?
    private var timer: Timer?
    
    // Physical screen and local coordinate physics
    private var targetScreen: NSScreen = .main ?? NSScreen.screens[0]
    private var localPosition: CGPoint = .zero
    private var velocity: CGVector = CGVector(dx: 5.0, dy: 5.0)
    private let cursorSize = NSSize(width: 120, height: 120)
    
    // Track launch time to prevent immediate dismiss
    private var startTime: Date = Date()
    private var checkActivityTimer: Timer?
    
    // Callback to notify main application that we stopped
    public var onStop: (() -> Void)?
    
    private let availableColors: [NSColor] = [
        .systemRed, .systemGreen, .systemBlue, .systemYellow, .systemOrange, 
        .systemPurple, .systemPink, .systemCyan, .systemMint
    ]
    private var currentNSColor: NSColor = .systemRed
    
    public init() {}
    
    public func start(style: ScreensaverStyle) {
        self.cursorStyle = style
        self.startTime = Date()
        
        // 1. Get the screen where the mouse cursor currently is
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens[0]
        self.targetScreen = screen
        
        // 2. Set initial position to current mouse position (relative to screen top-left)
        let localX = mouseLocation.x - screen.frame.origin.x
        let localY = screen.frame.origin.y + screen.frame.size.height - mouseLocation.y
        self.localPosition = CGPoint(x: localX, y: localY)
        
        // Set a random initial direction
        let angle = Double.random(in: 0.15...0.35) * Double.pi
        let speed: Double = 7.0
        let directionX = Bool.random() ? 1.0 : -1.0
        let directionY = Bool.random() ? 1.0 : -1.0
        self.velocity = CGVector(dx: cos(angle) * speed * directionX, dy: sin(angle) * speed * directionY)
        
        // Choose a random starting color
        self.currentNSColor = availableColors.randomElement() ?? .systemRed
        self.cursorColor = Color(currentNSColor)
        
        // 3. Create full-screen transparent window
        let overlay = OverlayWindow(screen: screen)
        self.window = overlay
        
        // 4. Generate and set the giant custom cursor on the overlay window
        let initialCursor = CursorGenerator.createCursor(color: currentNSColor, style: style, size: cursorSize)
        overlay.cursorView.currentCursor = initialCursor
        
        // 5. Show the window and make it key to receive clicks/keypresses for dismissal
        overlay.makeKeyAndOrderFront(nil)
        overlay.orderFrontRegardless()
        
        // 6. Listen to user activity notifications from the window
        NotificationCenter.default.addObserver(self, selector: #selector(handleActivity), name: NSNotification.Name("UserActivityDetected"), object: nil)
        
        // 7. Start animation loop (approx 60 FPS)
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updatePosition()
        }
        
        // 8. Start background activity polling (every 100ms)
        self.checkActivityTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkSystemActivity()
        }
    }
    
    @objc private func handleActivity() {
        self.stop()
    }
    
    public func stop() {
        // Stop timers
        timer?.invalidate()
        timer = nil
        checkActivityTimer?.invalidate()
        checkActivityTimer = nil
        
        // Remove observer
        NotificationCenter.default.removeObserver(self)
        
        // Close window
        window?.close()
        window = nil
        
        // Trigger callback
        onStop?()
    }
    
    private func updatePosition() {
        localPosition.x += velocity.dx
        localPosition.y += velocity.dy
        
        let screenW = targetScreen.frame.size.width
        let screenH = targetScreen.frame.size.height
        
        var minX: CGFloat = 0
        var maxX: CGFloat = screenW
        var minY: CGFloat = 0
        var maxY: CGFloat = screenH
        
        // Adjust limits based on cursor hotspot / bounding box
        switch cursorStyle {
        case .giantCursor, .hybrid:
            minX = 2
            maxX = screenW - 60
            minY = 2
            maxY = screenH - 90
        case .dvdLogo:
            minX = 60
            maxX = screenW - 60
            minY = 60
            maxY = screenH - 60
        }
        
        var bounced = false
        
        // Bounce Left / Right
        if localPosition.x <= minX {
            localPosition.x = minX
            velocity.dx = -velocity.dx
            bounced = true
        } else if localPosition.x >= maxX {
            localPosition.x = maxX
            velocity.dx = -velocity.dx
            bounced = true
        }
        
        // Bounce Top / Bottom
        if localPosition.y <= minY {
            localPosition.y = minY
            velocity.dy = -velocity.dy
            bounced = true
        } else if localPosition.y >= maxY {
            localPosition.y = maxY
            velocity.dy = -velocity.dy
            bounced = true
        }
        
        // Warp actual mouse cursor to new location
        warpMouseToLocal(x: localPosition.x, y: localPosition.y, screen: targetScreen)
        
        if bounced {
            changeColor()
        }
    }
    
    private func warpMouseToLocal(x: CGFloat, y: CGFloat, screen: NSScreen) {
        let mainScreenHeight = NSScreen.screens[0].frame.size.height
        
        // Convert local coordinate (origin top-left of target screen) to global CG coordinate (origin top-left of primary screen)
        let cocoaX = screen.frame.origin.x + x
        let cocoaY = screen.frame.origin.y + screen.frame.size.height - y
        
        let cgX = cocoaX
        let cgY = mainScreenHeight - cocoaY
        
        let targetPoint = CGPoint(x: cgX, y: cgY)
        CGWarpMouseCursorPosition(targetPoint)
    }
    
    private func changeColor() {
        let otherColors = availableColors.filter { $0 != currentNSColor }
        if let nextColor = otherColors.randomElement() {
            self.currentNSColor = nextColor
            self.cursorColor = Color(nextColor)
            
            // Rebuild the NSCursor and apply it to change shape color
            let newCursor = CursorGenerator.createCursor(color: nextColor, style: cursorStyle, size: cursorSize)
            window?.cursorView.currentCursor = newCursor
        }
    }
    
    private func checkSystemActivity() {
        // Prevent immediate dismissal during the first 0.5s of startup
        guard Date().timeIntervalSince(startTime) > 0.5 else { return }
        
        // Read hardware activity idle time
        let idleTime = IdleMonitor.getSystemIdleTime()
        
        // If system detects physical keyboard/mouse input, idleTime drops to 0
        if idleTime < 0.3 {
            self.stop()
        }
    }
}
