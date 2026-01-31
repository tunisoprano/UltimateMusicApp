//
//  ThemeManager.swift
//  MusicTuner
//
//  Apple-standard adaptive theme with light/dark mode support
//  Now includes user-selectable theme preference
//

import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return String(localized: "theme_system")
        case .light: return String(localized: "theme_light")
        case .dark: return String(localized: "theme_dark")
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Theme Manager

/// Centralized theme manager using Apple's adaptive color system
@MainActor
final class ThemeManager: ObservableObject {
    
    static let shared = ThemeManager()
    
    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.system.rawValue
    
    var currentTheme: AppTheme {
        get { AppTheme(rawValue: selectedThemeRaw) ?? .system }
        set { 
            selectedThemeRaw = newValue.rawValue 
            objectWillChange.send()
        }
    }
    
    var colorScheme: ColorScheme? {
        currentTheme.colorScheme
    }
    
    private init() {}
    
    // MARK: - Adaptive Colors (Automatically switch with system)
    
    /// Main background - adapts to light/dark mode
    var background: Color {
        Color(uiColor: .systemBackground)
    }
    
    /// Background gradient - subtle depth
    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(uiColor: .systemBackground),
                Color(uiColor: .secondarySystemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Card background - slightly elevated
    var cardBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }
    
    /// Primary text color
    var textPrimary: Color {
        Color(uiColor: .label)
    }
    
    /// Secondary text color
    var textSecondary: Color {
        Color(uiColor: .secondaryLabel)
    }
    
    /// Accent color - App's primary brand color (navy blue to match icon)
    var accent: Color {
        Color(hex: "1E3A5F") // Navy blue matching app icon
    }
    
    /// Success color - In tune indicator
    var success: Color {
        Color(uiColor: .systemGreen)
    }
    
    /// Warning color - Almost in tune
    var warning: Color {
        Color(uiColor: .systemOrange)
    }
    
    /// Error color - Out of tune
    var error: Color {
        Color(uiColor: .systemRed)
    }
    
    /// Inactive/disabled elements
    var inactive: Color {
        Color(uiColor: .tertiaryLabel)
    }
    
    /// Shadow color
    var shadow: Color {
        Color.black.opacity(0.1)
    }
    
    // MARK: - Gradients
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "1E3A5F"),
                Color(hex: "2D5A87")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var successGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(uiColor: .systemGreen),
                Color(uiColor: .systemGreen).opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Corner Radii (Apple HIG)
    
    static let radiusSmall: CGFloat = 10
    static let radiusMedium: CGFloat = 16
    static let radiusLarge: CGFloat = 22
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
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: ThemeManager.radiusMedium)
                    .fill(theme.cardBackground)
                    .shadow(
                        color: colorScheme == .dark ? .clear : theme.shadow,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
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
                    .shadow(color: theme.shadow, radius: configuration.isPressed ? 4 : 8, x: 0, y: configuration.isPressed ? 2 : 4)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
