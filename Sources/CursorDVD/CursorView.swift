import AppKit

public struct CursorGenerator {
    public static func createCursor(color: NSColor, size: NSSize) -> NSCursor {
        let image = NSImage(size: size)
        image.lockFocus()
        
        // Clear background
        NSColor.clear.set()
        NSRect(origin: .zero, size: size).fill()
        
        // Draw giant cursor path
        let path = NSBezierPath()
        // In AppKit, (0,0) is bottom-left
        path.move(to: NSPoint(x: 2, y: size.height - 2))
        path.line(to: NSPoint(x: 2, y: size.height - size.height * 0.8))
        path.line(to: NSPoint(x: size.width * 0.22, y: size.height - size.height * 0.6))
        path.line(to: NSPoint(x: size.width * 0.4, y: size.height - size.height * 0.98))
        path.line(to: NSPoint(x: size.width * 0.52, y: size.height - size.height * 0.93))
        path.line(to: NSPoint(x: size.width * 0.34, y: size.height - size.height * 0.55))
        path.line(to: NSPoint(x: size.width * 0.6, y: size.height - size.height * 0.55))
        path.close()
        
        color.set()
        path.fill()
        
        NSColor.white.set()
        path.lineWidth = 3
        path.stroke()
        
        image.unlockFocus()
        return NSCursor(image: image, hotSpot: NSPoint(x: 2, y: size.height - 2))
    }
}
