import SwiftData
import Foundation

@Model
final class Person {
    var id: UUID
    var name: String
    var birthdayDay: Int
    var birthdayMonth: Int
    var birthdayYear: Int?          // nil = unknown year → show pun
    var photoEmoji: String?         // emoji fallback when no contact photo
    var contactIdentifier: String?  // nil = manually added
    var isFavorite: Bool
    var notificationsEnabled: Bool
    var addedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        birthdayDay: Int,
        birthdayMonth: Int,
        birthdayYear: Int? = nil,
        photoEmoji: String? = nil,
        contactIdentifier: String? = nil,
        isFavorite: Bool = false,
        notificationsEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.birthdayDay = birthdayDay
        self.birthdayMonth = birthdayMonth
        self.birthdayYear = birthdayYear
        self.photoEmoji = photoEmoji
        self.contactIdentifier = contactIdentifier
        self.isFavorite = isFavorite
        self.notificationsEnabled = notificationsEnabled
        self.addedAt = Date()
    }

    // MARK: - Birthday helpers

    var nextBirthday: Date {
        let cal = Calendar.current
        let now = Date()
        let year = cal.component(.year, from: now)

        var comps = DateComponents()
        comps.month = birthdayMonth
        comps.day = birthdayDay
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        comps.year = year

        let thisYear = cal.date(from: comps)!
        if thisYear >= cal.startOfDay(for: now) {
            return thisYear
        }
        comps.year = year + 1
        return cal.date(from: comps)!
    }

    var daysUntilBirthday: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: nextBirthday)
        return cal.dateComponents([.day], from: today, to: target).day ?? 0
    }

    var isBirthdayToday: Bool {
        let cal = Calendar.current
        let now = Date()
        return birthdayMonth == cal.component(.month, from: now)
            && birthdayDay == cal.component(.day, from: now)
    }

    /// Age they will turn on their NEXT birthday. nil when birth year unknown.
    var turningAge: Int? {
        guard let year = birthdayYear else { return nil }
        let nextYear = Calendar.current.component(.year, from: nextBirthday)
        return nextYear - year
    }

    /// Human-readable age string, or a rotating pun when year is unknown.
    var ageDisplay: String {
        if let age = turningAge {
            return L10n.Birthday.turns(age)
        }
        return Person.agePun(for: id)
    }

    // MARK: - Pun pool

    static func agePun(for id: UUID) -> String {
        let puns: [String] = [
            "Forever 21",
            "Ageless wonder",
            "Timeless classic",
            "Age? Just a myth",
            "A fine vintage",
            "Born to be timeless",
            "The best-kept secret",
            "Eternally fabulous",
            "A mystery of the ages",
            "Younger every year",
            "Age is overrated",
            "Perfectly preserved",
            "Still loading…",
            "Classified info",
            "License to party: 00",
            "Vintage edition",
            "Error 404: Age not found",
            "Level: Legendary",
            "Too cool to count",
            "Beyond measure",
            "Peak performance, always",
            "Certified classic",
            "Rare limited edition",
            "Infinity + 1",
        ]
        let index = abs(id.hashValue) % puns.count
        return puns[index]
    }

    // MARK: - List grouping

    var birthdaySection: BirthdaySection {
        let days = daysUntilBirthday
        if days == 0 { return .today }
        if days <= 7 { return .thisWeek }
        if days <= 31 { return .thisMonth }
        return .later
    }
}

enum BirthdaySection: Int, CaseIterable, Comparable {
    case today, thisWeek, thisMonth, later

    static func < (lhs: BirthdaySection, rhs: BirthdaySection) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .today:     return L10n.Section.today
        case .thisWeek:  return L10n.Section.thisWeek
        case .thisMonth: return L10n.Section.thisMonth
        case .later:     return L10n.Section.later
        }
    }
}
