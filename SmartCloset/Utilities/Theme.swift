import SwiftUI

enum Theme {
    static let background = Color(hex: "FFF0F6") // Barbie Blush Pink
    static let primary = Color(hex: "FF69B4") // Hot Pink
    static let secondary = Color(hex: "FFD1DC") // Cotton Candy Pink
    static let text = Color(hex: "2C2C2C") // Rich Black
    static let cardBackground = Color.white // Diamond White
    
    static let gradientColors = [Color(hex: "F72585"), Color(hex: "FF69B4")]
    
    static let titleFont = Font.system(.title, design: .rounded).weight(.heavy)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded).weight(.light)
}

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