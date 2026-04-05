import SwiftUI

/// Central typography definitions.
/// Each theme may override font choices; these are the semantic roles.
enum BPFont {
    // Display
    static func displayLarge(_ weight: Font.Weight = .bold) -> Font {
        .system(size: 34, weight: weight, design: .rounded)
    }
    static func displayMedium(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: 28, weight: weight, design: .rounded)
    }

    // Title
    static func titleLarge(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: 22, weight: weight, design: .rounded)
    }
    static func titleMedium(_ weight: Font.Weight = .medium) -> Font {
        .system(size: 18, weight: weight, design: .rounded)
    }

    // Body
    static func bodyLarge() -> Font { .system(size: 16, weight: .regular) }
    static func bodyMedium() -> Font { .system(size: 14, weight: .regular) }

    // Caption
    static func caption() -> Font { .system(size: 12, weight: .regular) }
    static func captionBold() -> Font { .system(size: 12, weight: .semibold) }

    // Countdown number (big bold digit in badges)
    static func countdown() -> Font {
        .system(size: 20, weight: .bold, design: .rounded)
    }

    // Mid-Century uses serif style — swap via ThemeManager if needed
    static func midCenturyTitle() -> Font {
        .system(size: 22, weight: .bold, design: .serif)
    }
    static func midCenturyBody() -> Font {
        .system(size: 15, weight: .regular, design: .serif)
    }
}

/// Spacing scale
enum BPSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 12
    static let lg: CGFloat  = 16
    static let xl: CGFloat  = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

/// Corner radius scale
enum BPRadius {
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 12
    static let lg: CGFloat  = 16
    static let xl: CGFloat  = 24
    static let full: CGFloat = 999
}
