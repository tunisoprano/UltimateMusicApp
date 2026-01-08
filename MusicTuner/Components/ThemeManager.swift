//
//  ThemeManager.swift
//  MusicTuner
//
//  Created by MusicTuner
//

import SwiftUI

/// App theme options
enum AppTheme: String, CaseIterable, Identifiable {
    case cozy = "Cozy"
    case dark = "Dark"
    
    var id: String { rawValue }
}

/// Centralized theme manager for the app
@MainActor
final class ThemeManager: ObservableObject {
    
    static let shared = ThemeManager()
    
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.cozy.rawValue
    
    var currentTheme: AppTheme {
        get { AppTheme(rawValue: selectedThemeRaw) ?? .cozy }
        set { 
            selectedThemeRaw = newValue.rawValue
            objectWillChange.send()
        }
    }
    
    private init() {}
    
    // MARK: - Colors
    
    var background: Color {
        switch currentTheme {
        case .cozy: return Color(hex: "FAF9F6")
        case .dark: return Color(hex: "2C2C2C")
        }
    }
    
    var backgroundGradient: LinearGradient {
        switch currentTheme {
        case .cozy:
            return LinearGradient(
                colors: [Color(hex: "FAF9F6"), Color(hex: "F5F3EF")],
                startPoint: .top,
                endPoint: .bottom
            )
        case .dark:
            return LinearGradient(
                colors: [Color(hex: "2C2C2C"), Color(hex: "1F1F1F")],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    var cardBackground: Color {
        switch currentTheme {
        case .cozy: return Color(hex: "FFFFFF")
        case .dark: return Color(hex: "3A3A3A")
        }
    }
    
    var textPrimary: Color {
        switch currentTheme {
        case .cozy: return Color(hex: "4A4A4A")
        case .dark: return Color(hex: "E0E0E0")
        }
    }
    
    var textSecondary: Color {
        switch currentTheme {
        case .cozy: return Color(hex: "8A8A8A")
        case .dark: return Color(hex: "A0A0A0")
        }
    }
    
    var accent: Color {
        Color(hex: "D4A373") // Muted Terracotta - same for both themes
    }
    
    var success: Color {
        Color(hex: "84A98C") // Desaturated Sage Green
    }
    
    var warning: Color {
        Color(hex: "E9C46A") // Warm Yellow
    }
    
    var error: Color {
        Color(hex: "E07A5F") // Soft Coral
    }
    
    var inactive: Color {
        switch currentTheme {
        case .cozy: return Color(hex: "C4C4C4")
        case .dark: return Color(hex: "5A5A5A")
        }
    }
    
    var shadow: Color {
        switch currentTheme {
        case .cozy: return Color.black.opacity(0.06)
        case .dark: return Color.black.opacity(0.3)
        }
    }
    
    // MARK: - Accent Gradient
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accent.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var successGradient: LinearGradient {
        LinearGradient(
            colors: [success, success.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Corner Radii
    
    static let radiusSmall: CGFloat = 12
    static let radiusMedium: CGFloat = 20
    static let radiusLarge: CGFloat = 28
}

// MARK: - Color Extension

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
            (a, r, g, b) = (255, 128, 128, 128)
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

// MARK: - Theme Card Modifier

struct ThemeCardModifier: ViewModifier {
    @ObservedObject var theme = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                    .fill(theme.cardBackground)
                    .shadow(color: theme.shadow, radius: 12, x: 0, y: 6)
            )
    }
}

extension View {
    func themeCard() -> some View {
        self.modifier(ThemeCardModifier())
    }
}

// MARK: - Theme Button Style

struct ThemeButtonStyle: ButtonStyle {
    @ObservedObject var theme = ThemeManager.shared
    let isPrimary: Bool
    
    init(isPrimary: Bool = true) {
        self.isPrimary = isPrimary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(isPrimary ? .white : theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                    .fill(isPrimary ? theme.accentGradient : LinearGradient(colors: [theme.cardBackground], startPoint: .top, endPoint: .bottom))
                    .shadow(color: theme.shadow, radius: configuration.isPressed ? 4 : 10, x: 0, y: configuration.isPressed ? 2 : 5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
