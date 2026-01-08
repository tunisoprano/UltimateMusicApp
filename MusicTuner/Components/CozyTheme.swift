//
//  CozyTheme.swift
//  MusicTuner
//
//  Created by MusicTuner
//

import SwiftUI

/// Cozy Design System - Warm, Soft, and Inviting
enum CozyTheme {
    
    // MARK: - Color Palette
    
    /// Warm cream background
    static let background = Color(hex: "FDFBF7")
    
    /// Slightly darker cream for cards
    static let cardBackground = Color(hex: "F7F4EE")
    
    /// Warm charcoal for primary text
    static let textPrimary = Color(hex: "3C3C3C")
    
    /// Soft gray for secondary text
    static let textSecondary = Color(hex: "8A8A8A")
    
    /// Warm terracotta for primary actions
    static let accent = Color(hex: "E07A5F")
    
    /// Soft sage green for success/in-tune
    static let success = Color(hex: "81B29A")
    
    /// Warm yellow for "almost there"
    static let warning = Color(hex: "F2CC8F")
    
    /// Soft coral for "off" state
    static let error = Color(hex: "E07A5F")
    
    /// Muted brown for inactive elements
    static let inactive = Color(hex: "C4B7A6")
    
    /// Soft shadow color
    static let shadow = Color.black.opacity(0.06)
    
    // MARK: - Gradients
    
    /// Subtle warm background gradient
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(hex: "FDFBF7"),
            Color(hex: "F5F0E8")
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Warm accent gradient for buttons
    static let accentGradient = LinearGradient(
        colors: [
            Color(hex: "E07A5F"),
            Color(hex: "D66B4F")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Success gradient
    static let successGradient = LinearGradient(
        colors: [
            Color(hex: "81B29A"),
            Color(hex: "6FA389")
        ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
    )
    
    // MARK: - Shadows
    
    static func softShadow() -> some View {
        Color.clear
            .shadow(color: shadow, radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Corner Radii
    
    static let radiusSmall: CGFloat = 12
    static let radiusMedium: CGFloat = 20
    static let radiusLarge: CGFloat = 28
    static let radiusXL: CGFloat = 36
}

// MARK: - Cozy Button Style

struct CozyButtonStyle: ButtonStyle {
    let isPrimary: Bool
    
    init(isPrimary: Bool = true) {
        self.isPrimary = isPrimary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(isPrimary ? .white : CozyTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: CozyTheme.radiusMedium)
                    .fill(isPrimary ? CozyTheme.accentGradient : LinearGradient(colors: [CozyTheme.cardBackground], startPoint: .top, endPoint: .bottom))
                    .shadow(color: CozyTheme.shadow, radius: configuration.isPressed ? 4 : 10, x: 0, y: configuration.isPressed ? 2 : 5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Cozy Card Modifier

struct CozyCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: CozyTheme.radiusMedium)
                    .fill(CozyTheme.cardBackground)
                    .shadow(color: CozyTheme.shadow, radius: 12, x: 0, y: 6)
            )
    }
}

extension View {
    func cozyCard() -> some View {
        self.modifier(CozyCardModifier())
    }
}
