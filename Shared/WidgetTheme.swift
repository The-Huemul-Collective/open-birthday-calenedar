import SwiftUI

/// Lightweight theme for widgets — plain Color values only (no AnyShapeStyle needed).
struct WidgetTheme {
    let backgroundStart: Color
    let backgroundEnd: Color
    let cardFill: Color
    let cardOpacity: Double
    let usesBlur: Bool          // true = liquid glass style
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let favTint: Color
    let badgeFill: Color
    let badgeText: Color
    let divider: Color

    // MARK: - Factory

    static func current() -> WidgetTheme {
        make(for: AppThemeOption.current())
    }

    static func make(for option: AppThemeOption) -> WidgetTheme {
        switch option {
        case .gradient:    return gradient
        case .liquidGlass: return liquidGlass
        case .midCentury:  return midCentury
        }
    }

    // MARK: - Gradient (matches logo: hot-pink → purple, orange accent, teal secondary, gold fav)

    static let gradient = WidgetTheme(
        backgroundStart:  Color(red: 1.00, green: 0.36, blue: 0.68),  // hot pink
        backgroundEnd:    Color(red: 0.48, green: 0.25, blue: 0.75),  // purple
        cardFill:         Color.white,
        cardOpacity:      0.18,
        usesBlur:         false,
        textPrimary:      .white,
        textSecondary:    Color(red: 1.00, green: 0.88, blue: 0.95),
        accent:           Color(red: 1.00, green: 0.55, blue: 0.10),  // orange
        favTint:          Color(red: 1.00, green: 0.82, blue: 0.25),  // gold
        badgeFill:        Color(red: 1.00, green: 0.55, blue: 0.10),
        badgeText:        .white,
        divider:          Color.white.opacity(0.25)
    )

    // MARK: - Liquid Glass

    static let liquidGlass = WidgetTheme(
        backgroundStart:  Color(red: 0.55, green: 0.72, blue: 0.95),
        backgroundEnd:    Color(red: 0.72, green: 0.88, blue: 1.00),
        cardFill:         Color.white,
        cardOpacity:      0.25,
        usesBlur:         true,
        textPrimary:      Color(red: 0.05, green: 0.05, blue: 0.10),
        textSecondary:    Color(red: 0.25, green: 0.25, blue: 0.35),
        accent:           Color(red: 0.20, green: 0.45, blue: 0.90),
        favTint:          Color(red: 0.90, green: 0.65, blue: 0.10),
        badgeFill:        Color.white.opacity(0.35),
        badgeText:        Color(red: 0.20, green: 0.45, blue: 0.90),
        divider:          Color.white.opacity(0.30)
    )

    // MARK: - Mid Century

    static let midCentury = WidgetTheme(
        backgroundStart:  Color(red: 0.96, green: 0.92, blue: 0.84),
        backgroundEnd:    Color(red: 0.91, green: 0.85, blue: 0.74),
        cardFill:         Color(red: 0.98, green: 0.95, blue: 0.88),
        cardOpacity:      1.0,
        usesBlur:         false,
        textPrimary:      Color(red: 0.15, green: 0.10, blue: 0.08),
        textSecondary:    Color(red: 0.38, green: 0.28, blue: 0.22),
        accent:           Color(red: 0.78, green: 0.32, blue: 0.18),
        favTint:          Color(red: 0.15, green: 0.45, blue: 0.42),
        badgeFill:        Color(red: 0.78, green: 0.32, blue: 0.18),
        badgeText:        .white,
        divider:          Color(red: 0.78, green: 0.32, blue: 0.18).opacity(0.20)
    )
}
