import AppKit

public enum ScreensaverStyle: String, CaseIterable, Identifiable {
    case giantCursor = "Giant Cursor"
    case dvdLogo = "DVD Logo"
    case hybrid = "Hybrid (Cursor + DVD)"
    
    public var id: String { self.rawValue }
}

public struct CursorGenerator {
    public static func createCursor(color: NSColor, style: ScreensaverStyle, size: NSSize) -> NSCursor {
        let image = NSImage(size: size)
        image.lockFocus()
        
        // Clear background
        NSColor.clear.set()
        NSRect(origin: .zero, size: size).fill()
        
        switch style {
        case .giantCursor, .hybrid:
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
            
            if style == .hybrid {
                let font = NSFont.boldSystemFont(ofSize: size.height * 0.16)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: NSColor.white,
                    .backgroundColor: color.withAlphaComponent(0.8)
                ]
                let string = NSAttributedString(string: "DVD", attributes: attrs)
                string.draw(at: NSPoint(x: size.width * 0.45, y: size.height * 0.35))
            }
            
            image.unlockFocus()
            return NSCursor(image: image, hotSpot: NSPoint(x: 2, y: size.height - 2))
            
        case .dvdLogo:
            // Disc ellipse at the bottom
            let discPath = NSBezierPath(ovalIn: NSRect(x: size.width * 0.1, y: size.height * 0.1, width: size.width * 0.8, height: size.height * 0.2))
            color.set()
            discPath.lineWidth = 3
            discPath.stroke()
            
            // "DVD" text
            let font = NSFont.boldSystemFont(ofSize: size.height * 0.35)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]
            let string = NSAttributedString(string: "DVD", attributes: attrs)
            string.draw(in: NSRect(x: 0, y: size.height * 0.35, width: size.width, height: size.height * 0.45))
            
            // "VIDEO" text
            let subFont = NSFont.boldSystemFont(ofSize: size.height * 0.1)
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: subFont,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]
            let subString = NSAttributedString(string: "VIDEO", attributes: subAttrs)
            subString.draw(in: NSRect(x: 0, y: size.height * 0.22, width: size.width, height: size.height * 0.15))
            
            image.unlockFocus()
            return NSCursor(image: image, hotSpot: NSPoint(x: size.width / 2, y: size.height / 2))
        }
    }
}
