//
//  Theme.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI

struct Theme {
    // MARK: - Colors
    static let primaryColor = Color(red: 0.0, green: 0.7, blue: 1.0) // Azul vibrante
    static let secondaryColor = Color(red: 0.9, green: 0.4, blue: 0.1) // Laranja
    static let backgroundColor = Color(red: 0.08, green: 0.09, blue: 0.12) // Fundo escuro
    static let cardBackground = Color(red: 0.15, green: 0.16, blue: 0.18) // Cards escuros
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.7, green: 0.7, blue: 0.7)
    static let textTertiary = Color(red: 0.5, green: 0.5, blue: 0.5)
    
    // Status Colors
    static let successColor = Color.green
    static let warningColor = Color.orange
    static let errorColor = Color.red
    static let infoColor = Color.blue
    
    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [Color(red: 0.0, green: 0.7, blue: 1.0), Color(red: 0.2, green: 0.5, blue: 0.9)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let secondaryGradient = LinearGradient(
        colors: [Color(red: 0.9, green: 0.4, blue: 0.1), Color(red: 1.0, green: 0.6, blue: 0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.09, blue: 0.12),
            Color(red: 0.12, green: 0.13, blue: 0.16)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardGradient = LinearGradient(
        colors: [
            Color(red: 0.15, green: 0.16, blue: 0.18),
            Color(red: 0.18, green: 0.19, blue: 0.22)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Shadows
    struct Shadows {
        static let small = ShadowStyle(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        static let medium = ShadowStyle(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        static let large = ShadowStyle(color: .black.opacity(0.5), radius: 16, x: 0, y: 8)
        static let xlarge = ShadowStyle(color: .black.opacity(0.6), radius: 24, x: 0, y: 12)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        
        // Aliases for backward compatibility
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 24
        
        // Aliases
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
    
    // MARK: - Typography
    struct Typography {
        static let title: Font = .system(size: 42, weight: .bold, design: .rounded)
        static let headline: Font = .system(size: 24, weight: .bold, design: .rounded)
        static let subheadline: Font = .system(size: 18, weight: .semibold, design: .rounded)
        static let body: Font = .system(size: 16, weight: .regular, design: .default)
        static let bodyBold: Font = .system(size: 16, weight: .semibold, design: .default)
        static let caption: Font = .system(size: 14, weight: .medium, design: .default)
        static let caption2: Font = .system(size: 12, weight: .medium, design: .default)
        static let footnote: Font = .system(size: 11, weight: .regular, design: .default)
        
        // Monospaced fonts for data
        static let data: Font = .system(size: 12, weight: .medium, design: .monospaced)
        static let dataSmall: Font = .system(size: 11, weight: .medium, design: .monospaced)
    }
    
    // MARK: - Animation
    struct Animation {
        static let fast: Double = 0.2
        static let normal: Double = 0.3
        static let slow: Double = 0.5
        static let verySlow: Double = 1.0
        
        static let spring: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.7)
        static let easeInOut: SwiftUI.Animation = .easeInOut(duration: 0.3)
    }
    
    // MARK: - Opacity
    struct Opacity {
        static let disabled: Double = 0.5
        static let hover: Double = 0.1
        static let selected: Double = 0.2
        static let background: Double = 0.05
    }
}

// MARK: - Shadow Style
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Custom View Modifiers
struct ModernCardModifier: ViewModifier {
    var cornerRadius: CGFloat = Theme.CornerRadius.lg
    var shadow: ShadowStyle = Theme.Shadows.medium
    
    func body(content: Content) -> some View {
        content
            .background(Theme.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

struct GlassMorphismModifier: ViewModifier {
    var cornerRadius: CGFloat = Theme.CornerRadius.xl
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            )
    }
}


// MARK: - View Extensions
extension View {
    // Card modifiers
    func modernCard(cornerRadius: CGFloat = Theme.CornerRadius.lg, shadow: ShadowStyle = Theme.Shadows.medium) -> some View {
        self.modifier(ModernCardModifier(cornerRadius: cornerRadius, shadow: shadow))
    }
    
    func glassMorphism(cornerRadius: CGFloat = Theme.CornerRadius.xl) -> some View {
        self.modifier(GlassMorphismModifier(cornerRadius: cornerRadius))
    }
    
    // Typography modifiers
    func titleStyle() -> some View {
        self.font(Theme.Typography.title)
            .foregroundColor(Theme.textPrimary)
    }
    
    func headlineStyle() -> some View {
        self.font(Theme.Typography.headline)
            .foregroundColor(Theme.textPrimary)
    }
    
    func subheadlineStyle() -> some View {
        self.font(Theme.Typography.subheadline)
            .foregroundColor(Theme.textPrimary)
    }
    
    func bodyStyle() -> some View {
        self.font(Theme.Typography.body)
            .foregroundColor(Theme.textPrimary)
    }
    
    func captionStyle() -> some View {
        self.font(Theme.Typography.caption)
            .foregroundColor(Theme.textSecondary)
    }
    
    func footnoteStyle() -> some View {
        self.font(Theme.Typography.footnote)
            .foregroundColor(Theme.textTertiary)
    }
    
    func dataStyle() -> some View {
        self.font(Theme.Typography.data)
            .foregroundColor(Theme.textSecondary)
    }
    
    // Layout modifiers
    func fillCard() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
            .modernCard()
    }
    
    func fixedCard(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        self.frame(width: width, height: height)
            .modernCard()
    }
}

// MARK: - Backward Compatibility Aliases
extension Theme {
    // Spacing aliases
    static let spacingSmall: CGFloat = Spacing.sm
    static let spacingMedium: CGFloat = Spacing.md
    static let spacingLarge: CGFloat = Spacing.lg
    static let spacingXLarge: CGFloat = Spacing.xl
    
    // Shadow aliases
    static let shadowLight: ShadowStyle = Shadows.small
    static let shadowMedium: ShadowStyle = Shadows.medium
    
    // Corner radius aliases
    static let cornerRadiusSmall: CGFloat = CornerRadius.sm
    static let cornerRadiusMedium: CGFloat = CornerRadius.md
    static let cornerRadiusLarge: CGFloat = CornerRadius.lg
}

// MARK: - Color Extensions for Settings
extension Color {
    // Helper for settings preview
    static let systemBlue = Color.blue
    static let systemGreen = Color.green
    static let systemOrange = Color.orange
    static let systemPurple = Color.purple
    static let systemRed = Color.red
    static let systemTeal = Color.teal
}

// MARK: - Preview Helper
struct ThemePreview: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("Theme Preview")
                .titleStyle()
            
            HStack(spacing: Theme.Spacing.md) {
                ThemeColorPreview(color: Theme.primaryColor)
                ThemeColorPreview(color: Theme.secondaryColor)
                ThemeColorPreview(color: Theme.backgroundColor)
                ThemeColorPreview(color: Theme.cardBackground)
            }
            
            VStack(spacing: Theme.Spacing.md) {
                Text("Headline Style")
                    .headlineStyle()
                
                Text("Subheadline Style")
                    .subheadlineStyle()
                
                Text("Body Style")
                    .bodyStyle()
                
                Text("Caption Style")
                    .captionStyle()
                
                Text("Data Style")
                    .dataStyle()
            }
            .modernCard()
            .padding()
        }
        .padding()
        .background(Theme.backgroundColor)
    }
}

// MARK: - Supporting Views for Preview
struct ThemeColorPreview: View {
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
            
            Text("Cor")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(width: 60)
    }
}

#Preview {
    ThemePreview()
        .frame(width: 400, height: 400)
}
