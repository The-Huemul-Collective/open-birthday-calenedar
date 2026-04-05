import SwiftUI

struct LiquidGlassTheme: AppTheme {
    let name = "Liquid Glass"

    // MARK: - Backgrounds

    var backgroundPrimary: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [Color("GlassBgTop"), Color("GlassBgBottom")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    var backgroundSecondary: AnyShapeStyle {
        AnyShapeStyle(.ultraThinMaterial)
    }

    var cardBackground: AnyShapeStyle {
        AnyShapeStyle(.ultraThinMaterial)
    }

    var navigationBarBackground: AnyShapeStyle {
        AnyShapeStyle(.thinMaterial)
    }

    var widgetBackground: AnyShapeStyle {
        AnyShapeStyle(.ultraThinMaterial)
    }

    // MARK: - Text

    var textPrimary: Color   { Color("GlassTextPrimary") }
    var textSecondary: Color { Color("GlassTextSecondary") }
    var textTertiary: Color  { Color("GlassTextTertiary") }

    // MARK: - Accent

    var accent: Color          { Color("GlassAccent") }
    var accentSecondary: Color { Color("GlassAccentSecondary") }
    var favoriteTint: Color    { Color("GlassFav") }

    // MARK: - Badge

    var badgeBackground: AnyShapeStyle {
        AnyShapeStyle(.regularMaterial)
    }
    var badgeText: Color { Color("GlassAccent") }

    // MARK: - Misc

    var sectionHeaderText: Color { Color("GlassTextSecondary") }

    var navigationColorScheme: ColorScheme { .dark }

    var avatarRing: AnyShapeStyle {
        AnyShapeStyle(Color("GlassAccent").opacity(0.6))
    }
}
