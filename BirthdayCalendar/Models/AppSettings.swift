import Foundation
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let defaults = UserDefaults(suiteName: "group.com.open.birthdaycalendar")!

    @Published var theme: AppThemeOption {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }

    /// How many days before the birthday to send fav early reminder (default 7)
    @Published var favEarlyReminderDays: Int {
        didSet { defaults.set(favEarlyReminderDays, forKey: Keys.favEarlyDays) }
    }

    /// Hour for standard notifications (0–23, default 9)
    @Published var reminderHour: Int {
        didSet { defaults.set(reminderHour, forKey: Keys.reminderHour) }
    }

    /// Minute for standard notifications (0–59, default 0)
    @Published var reminderMinute: Int {
        didSet { defaults.set(reminderMinute, forKey: Keys.reminderMinute) }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.onboarded) }
    }

    private init() {
        let raw = defaults.string(forKey: Keys.theme) ?? AppThemeOption.gradient.rawValue
        self.theme = AppThemeOption(rawValue: raw) ?? .gradient
        self.favEarlyReminderDays = defaults.integer(forKey: Keys.favEarlyDays).nonZero ?? 7
        self.reminderHour = defaults.integer(forKey: Keys.reminderHour).nonZero ?? 9
        self.reminderMinute = defaults.integer(forKey: Keys.reminderMinute)
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.onboarded)
    }

    private enum Keys {
        static let theme        = "appTheme"
        static let favEarlyDays = "favEarlyReminderDays"
        static let reminderHour = "reminderHour"
        static let reminderMinute = "reminderMinute"
        static let onboarded    = "hasCompletedOnboarding"
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
