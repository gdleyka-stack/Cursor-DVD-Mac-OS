import SwiftUI

public enum ScreensaverStyle: String, CaseIterable, Identifiable {
    case giantCursor = "Giant Cursor"
    case dvdLogo = "DVD Logo"
    case hybrid = "Hybrid (Cursor + DVD)"
    
    public var id: String { self.rawValue }
}

public struct CursorView: View {
    public var color: Color
    public var style: ScreensaverStyle
    
    public var body: some View {
        VStack(spacing: 8) {
            switch style {
            case .giantCursor:
                cursorShape
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 0)
                    .overlay(
                        cursorShape
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .frame(width: 80, height: 120)
                
            case .dvdLogo:
                dvdLogoText
                
            case .hybrid:
                ZStack(alignment: .topLeading) {
                    cursorShape
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: color.opacity(0.5), radius: 10, x: 0, y: 0)
                        .overlay(
                            cursorShape
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .frame(width: 70, height: 105)
                    
                    Text("DVD")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.8))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                        .offset(x: 45, y: 55)
                        .shadow(radius: 4)
                }
                .frame(width: 120, height: 120)
            }
        }
    }
    
    // Custom Path for classic macOS mouse cursor
    private var cursorShape: Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 78))
            path.addLine(to: CGPoint(x: 21, y: 58))
            path.addLine(to: CGPoint(x: 39, y: 98))
            path.addLine(to: CGPoint(x: 51, y: 93))
            path.addLine(to: CGPoint(x: 33, y: 53))
            path.addLine(to: CGPoint(x: 58, y: 53))
            path.closeSubpath()
        }
    }
    
    private var dvdLogoText: some View {
        VStack(spacing: -5) {
            Text("DVD")
                .font(.system(size: 48, weight: .black, design: .serif))
                .italic()
                .tracking(2)
                .foregroundColor(color)
                .shadow(color: color.opacity(0.6), radius: 8)
            
            Text("VIDEO")
                .font(.system(size: 14, weight: .bold, design: .default))
                .tracking(9)
                .foregroundColor(color)
                .padding(.horizontal, 4)
                .shadow(color: color.opacity(0.4), radius: 4)
            
            // The classic DVD disc oval at the bottom
            Ellipse()
                .stroke(color, lineWidth: 3)
                .frame(width: 100, height: 15)
                .shadow(color: color.opacity(0.5), radius: 4)
                .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
        )
    }
}
