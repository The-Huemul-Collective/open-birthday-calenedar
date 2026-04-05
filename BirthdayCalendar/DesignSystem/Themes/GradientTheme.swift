import SwiftUI

struct GradientTheme: AppTheme {
    let name = "Gradient"

    // MARK: - Backgrounds

    var backgroundPrimary: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [Color("GradBgTop"), Color("GradBgBottom")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    var backgroundSecondary: AnyShapeStyle {
        AnyShapeStyle(Color("GradSurface"))
    }

    // Cards are white/frosted so they stand out against the vivid gradient
    var cardBackground: AnyShapeStyle {
        AnyShapeStyle(Color.white.opacity(0.18))
    }

    var navigationBarBackground: AnyShapeStyle {
        AnyShapeStyle(Color("GradNavBar").opacity(0.85))
    }

    var widgetBackground: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [Color("GradBgTop"), Color("GradBgBottom")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Text (white on vivid gradient)

    var textPrimary: Color   { .white }
    var textSecondary: Color { Color("GradTextSecondary") }
    var textTertiary: Color  { Color("GradTextTertiary") }

    // MARK: - Accent

    var accent: Color          { Color("GradAccent") }           // orange
    var accentSecondary: Color { Color("GradAccentSecondary") }  // teal
    var favoriteTint: Color    { Color("GradFav") }              // gold

    // MARK: - Badge

    var badgeBackground: AnyShapeStyle {
        AnyShapeStyle(Color("GradAccent"))
    }
    var badgeText: Color { .white }

    // MARK: - Misc

    var sectionHeaderText: Color { Color("GradTextSecondary") }

    var avatarRing: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [Color("GradAccent"), Color("GradBgTop")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    var navigationColorScheme: ColorScheme { .dark }
}
