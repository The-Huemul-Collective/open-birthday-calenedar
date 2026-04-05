import SwiftUI

struct MidCenturyTheme: AppTheme {
    let name = "Mid Century"

    // MARK: - Backgrounds

    var backgroundPrimary: AnyShapeStyle {
        AnyShapeStyle(Color("MCBg"))
    }

    var backgroundSecondary: AnyShapeStyle {
        AnyShapeStyle(Color("MCSurface"))
    }

    var cardBackground: AnyShapeStyle {
        AnyShapeStyle(Color("MCCard"))
    }

    var navigationBarBackground: AnyShapeStyle {
        AnyShapeStyle(Color("MCNavBar"))
    }

    var widgetBackground: AnyShapeStyle {
        AnyShapeStyle(Color("MCBg"))
    }

    // MARK: - Text

    var textPrimary: Color   { Color("MCTextPrimary") }
    var textSecondary: Color { Color("MCTextSecondary") }
    var textTertiary: Color  { Color("MCTextTertiary") }

    // MARK: - Accent

    var accent: Color          { Color("MCAccent") }       // warm terracotta
    var accentSecondary: Color { Color("MCAccentSecondary") } // mustard gold
    var favoriteTint: Color    { Color("MCFav") }           // deep teal

    // MARK: - Badge

    var badgeBackground: AnyShapeStyle {
        AnyShapeStyle(Color("MCAccent"))
    }
    var badgeText: Color { .white }

    // MARK: - Misc

    var sectionHeaderText: Color { Color("MCTextSecondary") }

    var navigationColorScheme: ColorScheme { .light }

    var avatarRing: AnyShapeStyle {
        AnyShapeStyle(Color("MCAccentSecondary"))
    }
}
