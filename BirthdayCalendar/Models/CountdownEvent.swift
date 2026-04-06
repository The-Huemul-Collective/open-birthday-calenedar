import SwiftData
import Foundation

// MARK: - Supporting Enums

enum EventRepeatRule: String, CaseIterable, Codable {
    case never   = "Never"
    case daily   = "Daily"
    case weekly  = "Weekly"
    case monthly = "Monthly"
    case yearly  = "Yearly"
}

enum EventWhatsNext: String, CaseIterable, Codable {
    case stayAtZero = "Stay at zero"
    case countUp    = "Count up again"
    case delete     = "Delete"
    case archive    = "Archive"
}

enum EventFormattingUnit: String, CaseIterable, Codable {
    case days   = "Days"
    case weeks  = "Weeks"
    case months = "Months"
    case years  = "Years"
}

// MARK: - Model

@Model
final class CountdownEvent {
    var id: UUID
    var title: String
    var icon: String                   // emoji
    var eventDate: Date
    var hasTime: Bool
    var repeatRuleRaw: String
    var whatsNextRaw: String
    var photoData: Data?               // photo frame background
    var notificationsEnabled: Bool
    var earlyReminderDays: Int         // 0 = none
    var startDate: Date
    var isArchived: Bool
    var excludeWeekends: Bool
    var formattingUnitRaw: String

    var repeatRule: EventRepeatRule {
        get { EventRepeatRule(rawValue: repeatRuleRaw) ?? .never }
        set { repeatRuleRaw = newValue.rawValue }
    }
    var whatsNext: EventWhatsNext {
        get { EventWhatsNext(rawValue: whatsNextRaw) ?? .stayAtZero }
        set { whatsNextRaw = newValue.rawValue }
    }
    var formattingUnit: EventFormattingUnit {
        get { EventFormattingUnit(rawValue: formattingUnitRaw) ?? .days }
        set { formattingUnitRaw = newValue.rawValue }
    }
    var textColorHex: String?          // nil = use theme default
    var friendIDsCSV: String           // comma-separated UUID strings, "" = none
    var addedAt: Date

    /// Resolved list of friend UUID strings.
    var friendIDs: [String] {
        get { friendIDsCSV.isEmpty ? [] : friendIDsCSV.components(separatedBy: ",") }
        set { friendIDsCSV = newValue.joined(separator: ",") }
    }

    init(
        id: UUID = UUID(),
        title: String = "",
        icon: String = "🎉",
        eventDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
        hasTime: Bool = false,
        repeatRule: EventRepeatRule = .never,
        whatsNext: EventWhatsNext = .stayAtZero,
        photoData: Data? = nil,
        notificationsEnabled: Bool = true,
        earlyReminderDays: Int = 0,
        startDate: Date = Date(),
        isArchived: Bool = false,
        excludeWeekends: Bool = false,
        formattingUnit: EventFormattingUnit = .days,
        textColorHex: String? = nil,
        friendIDsCSV: String = ""
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.eventDate = eventDate
        self.hasTime = hasTime
        self.repeatRuleRaw = repeatRule.rawValue
        self.whatsNextRaw = whatsNext.rawValue
        self.photoData = photoData
        self.notificationsEnabled = notificationsEnabled
        self.earlyReminderDays = earlyReminderDays
        self.startDate = startDate
        self.isArchived = isArchived
        self.excludeWeekends = excludeWeekends
        self.formattingUnitRaw = formattingUnit.rawValue
        self.textColorHex = textColorHex
        self.friendIDsCSV = friendIDsCSV
        self.addedAt = Date()
    }

    // MARK: - Countdown helpers

    var rawDaysUntilEvent: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: eventDate)
        return cal.dateComponents([.day], from: today, to: target).day ?? 0
    }

    var daysUntilEvent: Int {
        let raw = rawDaysUntilEvent
        guard excludeWeekends, raw > 0 else { return raw }
        let cal = Calendar.current
        var weekdays = 0
        var current = cal.startOfDay(for: Date())
        for _ in 0..<raw {
            current = cal.date(byAdding: .day, value: 1, to: current)!
            let weekday = cal.component(.weekday, from: current)
            if weekday != 1 && weekday != 7 { weekdays += 1 }
        }
        return weekdays
    }

    var isEventToday: Bool { rawDaysUntilEvent == 0 }
    var isPast: Bool { rawDaysUntilEvent < 0 }
    var isCountingUp: Bool { isPast && whatsNext == .countUp }

    var countdownValue: Int {
        let days = abs(daysUntilEvent)
        switch formattingUnit {
        case .days:
            return days
        case .weeks:
            return days / 7
        case .months:
            let cal = Calendar.current
            let (from, to) = isPast ? (eventDate, Date()) : (Date(), eventDate)
            return abs(cal.dateComponents([.month], from: from, to: to).month ?? 0)
        case .years:
            let cal = Calendar.current
            let (from, to) = isPast ? (eventDate, Date()) : (Date(), eventDate)
            return abs(cal.dateComponents([.year], from: from, to: to).year ?? 0)
        }
    }

    var countdownLabel: String {
        let v = countdownValue
        switch formattingUnit {
        case .days:   return v == 1 ? "day" : "days"
        case .weeks:  return v == 1 ? "week" : "weeks"
        case .months: return v == 1 ? "month" : "months"
        case .years:  return v == 1 ? "year" : "years"
        }
    }

    var eventSection: EventSection {
        if isCountingUp { return .countingUp }
        let days = rawDaysUntilEvent
        if days == 0  { return .today }
        if days <= 7  { return .thisWeek }
        if days <= 31 { return .thisMonth }
        return .later
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = hasTime ? .short : .none
        return f.string(from: eventDate)
    }

    var shortFormattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = hasTime ? .short : .none
        return f.string(from: eventDate)
    }
}

// MARK: - Section

enum EventSection: Int, CaseIterable, Comparable {
    case countingUp, today, thisWeek, thisMonth, later

    static func < (lhs: EventSection, rhs: EventSection) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .countingUp: return "Counting Up"
        case .today:      return "Today"
        case .thisWeek:   return "This Week"
        case .thisMonth:  return "This Month"
        case .later:      return "Later"
        }
    }
}
