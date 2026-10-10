import SwiftUI

enum AppTheme {
    static let darkBackground   = Color(hex: "07090E")
    static let darkSurface      = Color(hex: "121620")
    static let darkSurfaceAlt   = Color(hex: "181D2A")
    static let inputBackground  = Color(hex: "1B2130")
    static let inputBorder      = Color(hex: "293245")
    static let inputBorderFocus = Color(hex: "38BDF8")

    static let electricBlue     = Color(hex: "2563EB")
    static let skyCyan          = Color(hex: "38BDF8")
    static let indigoAccent     = Color(hex: "6366F1")
    static let accentMint       = Color(hex: "10B981")
    static let accentCoral      = Color(hex: "EF4444")

    static let textPrimary      = Color(hex: "FFFFFF")
    static let textSecondary    = Color(hex: "94A3B8")
    static let textMuted        = Color(hex: "64748B")

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [electricBlue, skyCyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var logoGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "3B82F6"), Color(hex: "60A5FA"), Color(hex: "6366F1")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "1D4ED8"), Color(hex: "2563EB"), Color(hex: "0284C7")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var ambientGlow: RadialGradient {
        RadialGradient(
            colors: [electricBlue.opacity(0.35), skyCyan.opacity(0.12), Color.clear],
            center: .center,
            startRadius: 20,
            endRadius: 220
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct CustomCorners: Shape {
    var radius: CGFloat = 24
    var corners: UIRectCorner = [.topLeft, .topRight]

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
