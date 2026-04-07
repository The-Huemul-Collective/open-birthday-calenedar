import Foundation

/// Lightweight event model shared between main app and widget extension.
/// Converted from CountdownEvent (SwiftData) and serialised to the App Group JSON store.
struct WidgetEvent: Codable, Identifiable {
    let id: UUID
    let title: String
    let icon: String
    let eventDate: Date
    let hasTime: Bool
    let formattingUnitRaw: String   // "Days" | "Weeks" | "Months" | "Years"
    let photoFileName: String?      // JPEG saved in App Group container; nil = no photo
    let textColorHex: String?       // nil = use theme default
    let friendIDs: [String]         // Person UUID strings
    let notificationsEnabled: Bool

    // MARK: - Calendar-based countdown (matches app display)

    var daysUntilEvent: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: eventDate)
        return cal.dateComponents([.day], from: today, to: target).day ?? 0
    }

    var isPast: Bool  { daysUntilEvent < 0 }
    var isToday: Bool { daysUntilEvent == 0 }

    var countdownValue: Int {
        let days = abs(daysUntilEvent)
        switch formattingUnitRaw {
        case "Weeks":
            return days / 7
        case "Months":
            let cal = Calendar.current
            let (from, to) = isPast ? (eventDate, Date()) : (Date(), eventDate)
            return abs(cal.dateComponents([.month], from: from, to: to).month ?? 0)
        case "Years":
            let cal = Calendar.current
            let (from, to) = isPast ? (eventDate, Date()) : (Date(), eventDate)
            return abs(cal.dateComponents([.year], from: from, to: to).year ?? 0)
        default:
            return days
        }
    }

    var countdownLabel: String {
        let v = countdownValue
        switch formattingUnitRaw {
        case "Weeks":  return v == 1 ? "week" : "weeks"
        case "Months": return v == 1 ? "month" : "months"
        case "Years":  return v == 1 ? "year" : "years"
        default:       return v == 1 ? "day" : "days"
        }
    }

    var shortFormattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = hasTime ? .short : .none
        return f.string(from: eventDate)
    }

    // MARK: - Seconds-based (live countdown widget)

    /// Total seconds until event, clamped to 0.
    var totalSecondsUntilEvent: Double {
        max(0, eventDate.timeIntervalSinceNow)
    }

    /// Integer days based on total seconds (may differ from calendar days by 1 depending on time of day).
    var secondsBasedDays: Int {
        Int(totalSecondsUntilEvent / 86400)
    }

    /// A date that makes Text(.timer) display only the sub-day HH:MM:SS portion of the countdown.
    /// Trick: eventDate − (days × 86400) seconds. The timer counts down from that sub-day offset.
    var subDayTimerDate: Date {
        let subDay = totalSecondsUntilEvent.truncatingRemainder(dividingBy: 86400)
        return Date().addingTimeInterval(subDay)
    }
}

// MARK: - Preview placeholders (Xcode gallery / snapshot)

extension WidgetEvent {
    static let placeholder = WidgetEvent(
        id: UUID(uuidString: "EEEEEEEE-0000-0000-0000-000000000001")!,
        title: "Surf Camp",
        icon: "🏄",
        eventDate: Calendar.current.date(byAdding: .day, value: 47, to: Date())!,
        hasTime: false,
        formattingUnitRaw: "Days",
        photoFileName: nil,
        textColorHex: nil,
        friendIDs: [],
        notificationsEnabled: true
    )

    static let placeholder2 = WidgetEvent(
        id: UUID(uuidString: "EEEEEEEE-0000-0000-0000-000000000002")!,
        title: "NYC Trip",
        icon: "✈️",
        eventDate: Calendar.current.date(byAdding: .day, value: 12, to: Date())!,
        hasTime: false,
        formattingUnitRaw: "Days",
        photoFileName: nil,
        textColorHex: nil,
        friendIDs: [],
        notificationsEnabled: false
    )
}
