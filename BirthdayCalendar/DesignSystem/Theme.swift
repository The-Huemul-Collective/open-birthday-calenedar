import SwiftUI

// MARK: - Theme Protocol

protocol AppTheme {
    var name: String { get }

    // Backgrounds
    var backgroundPrimary: AnyShapeStyle { get }
    var backgroundSecondary: AnyShapeStyle { get }
    var cardBackground: AnyShapeStyle { get }
    var navigationBarBackground: AnyShapeStyle { get }

    // Text
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var textTertiary: Color { get }

    // Accent & tints
    var accent: Color { get }
    var accentSecondary: Color { get }
    var favoriteTint: Color { get }

    // Countdown badge
    var badgeBackground: AnyShapeStyle { get }
    var badgeText: Color { get }

    // Section header
    var sectionHeaderText: Color { get }

    // Avatar ring
    var avatarRing: AnyShapeStyle { get }

    // Widget background
    var widgetBackground: AnyShapeStyle { get }

    /// Drives .toolbarColorScheme so the nav bar title + icons are readable
    var navigationColorScheme: ColorScheme { get }
}

// MARK: - Theme Manager

final class ThemeManager: ObservableObject {
    @Published var current: any AppTheme

    init(option: AppThemeOption = .gradient) {
        self.current = ThemeManager.theme(for: option)
    }

    func apply(_ option: AppThemeOption) {
        current = ThemeManager.theme(for: option)
    }

    static func theme(for option: AppThemeOption) -> any AppTheme {
        switch option {
        case .gradient:    return GradientTheme()
        case .liquidGlass: return LiquidGlassTheme()
        case .midCentury:  return MidCenturyTheme()
        }
    }
}

// MARK: - Environment Key

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}
