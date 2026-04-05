import Foundation

// MARK: - Theme option (shared so widgets can read it from UserDefaults)

enum AppThemeOption: String, CaseIterable, Codable {
    case gradient    = "Gradient"
    case liquidGlass = "Liquid Glass"
    case midCentury  = "Mid Century"

    static func current() -> AppThemeOption {
        let raw = UserDefaults(suiteName: "group.com.open.birthdaycalendar")?
            .string(forKey: "appTheme") ?? AppThemeOption.gradient.rawValue
        return AppThemeOption(rawValue: raw) ?? .gradient
    }
}

// MARK: - Lightweight birthday entry used by both the widget and the main app
/// to avoid importing SwiftData into the widget extension.
struct WidgetPerson: Codable, Identifiable {
    let id: UUID
    let name: String
    let birthdayDay: Int
    let birthdayMonth: Int
    let birthdayYear: Int?
    let photoEmoji: String?
    let photoFileName: String?   // JPEG saved in App Group container
    let isFavorite: Bool

    var nextBirthday: Date {
        let cal = Calendar.current
        let now = Date()
        let year = cal.component(.year, from: now)

        var comps = DateComponents()
        comps.month = birthdayMonth
        comps.day = birthdayDay
        comps.year = year

        let thisYear = cal.date(from: comps)!
        if thisYear >= cal.startOfDay(for: now) { return thisYear }
        comps.year = year + 1
        return cal.date(from: comps)!
    }

    var daysUntilBirthday: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: nextBirthday)
        return cal.dateComponents([.day], from: today, to: target).day ?? 0
    }

    var ageDisplay: String {
        guard let year = birthdayYear else {
            return agePun
        }
        let nextYear = Calendar.current.component(.year, from: nextBirthday)
        return "Turns \(nextYear - year)"
    }

    private var agePun: String {
        let puns = [
            "Forever 21", "Ageless wonder", "Timeless classic",
            "A fine vintage", "Born to be timeless", "Eternally fabulous",
            "Error 404: Age not found", "Level: Legendary", "Certified classic",
        ]
        return puns[abs(id.hashValue) % puns.count]
    }
}
