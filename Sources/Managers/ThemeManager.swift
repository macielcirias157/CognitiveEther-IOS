import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
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

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    // Lumina AI Palette
    let surface = Color(hex: "#0E0E11")
    let surfaceContainerLow = Color(hex: "#131316")
    let surfaceContainer = Color(hex: "#19191D")
    let surfaceContainerHigh = Color(hex: "#1F1F23")
    let surfaceContainerHighest = Color(hex: "#25252A")
    let surfaceVariant = Color(hex: "#25252A")
    
    let primary = Color(hex: "#A4A5FF")
    let primaryDim = Color(hex: "#5F5EFF")
    let electricIndigo = Color(hex: "#5D5CFF")
    
    let onSurface = Color(hex: "#F0EDF1")
    let outlineVariant = Color(hex: "#48474B")
    
    let primaryGradient = LinearGradient(
        colors: [Color(hex: "#5F5EFF"), Color(hex: "#A4A5FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    func appFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // Fallback to SF Pro (system font) if Inter is not available
        return Font.system(size: size, weight: weight, design: .default)
    }
}
