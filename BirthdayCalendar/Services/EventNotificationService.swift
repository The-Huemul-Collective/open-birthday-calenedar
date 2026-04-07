import UserNotifications
import Foundation

final class EventNotificationService {
    static let shared = EventNotificationService()
    private let center = UNUserNotificationCenter.current()

    func scheduleNotifications(for event: CountdownEvent, settings: AppSettings) async {
        await removeNotifications(for: event)
        guard event.notificationsEnabled else { return }

        let cal = Calendar.current
        let hour   = event.hasTime ? cal.component(.hour,   from: event.eventDate) : settings.reminderHour
        let minute = event.hasTime ? cal.component(.minute, from: event.eventDate) : settings.reminderMinute

        // Skip past non-repeating events
        if event.isPast && event.repeatRule == .never { return }

        // Same-day notification
        let content = UNMutableNotificationContent()
        content.title = "\(event.icon) \(event.title)"
        content.body  = event.isEventToday ? "Today is the day!" : "Your countdown event is here!"
        content.sound = .default

        let repeats = event.repeatRule != .never
        let comps   = triggerComponents(for: event, hour: hour, minute: minute)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: repeats)
        let request = UNNotificationRequest(
            identifier: notifID(event: event, kind: "event"),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)

        // Early reminder (only for non-repeating or yearly events)
        guard event.earlyReminderDays > 0,
              event.repeatRule == .never || event.repeatRule == .yearly,
              let earlyDate = cal.date(byAdding: .day, value: -event.earlyReminderDays, to: event.eventDate),
              earlyDate > Date()
        else { return }

        var earlyComps = cal.dateComponents([.month, .day], from: earlyDate)
        earlyComps.hour   = hour
        earlyComps.minute = minute
        if event.repeatRule == .never {
            earlyComps.year = cal.component(.year, from: earlyDate)
        }

        let earlyContent = UNMutableNotificationContent()
        earlyContent.title = "\(event.icon) \(event.title) in \(event.earlyReminderDays) days!"
        earlyContent.body  = "Start getting ready."
        earlyContent.sound = .default

        let earlyTrigger = UNCalendarNotificationTrigger(
            dateMatching: earlyComps,
            repeats: event.repeatRule == .yearly
        )
        let earlyRequest = UNNotificationRequest(
            identifier: notifID(event: event, kind: "early"),
            content: earlyContent,
            trigger: earlyTrigger
        )
        try? await center.add(earlyRequest)
    }

    func removeNotifications(for event: CountdownEvent) async {
        center.removePendingNotificationRequests(withIdentifiers: [
            notifID(event: event, kind: "event"),
            notifID(event: event, kind: "early"),
        ])
    }

    // MARK: - Private

    private func notifID(event: CountdownEvent, kind: String) -> String {
        "countdown.\(event.id.uuidString).\(kind)"
    }

    private func triggerComponents(for event: CountdownEvent, hour: Int, minute: Int) -> DateComponents {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.hour   = hour
        comps.minute = minute

        switch event.repeatRule {
        case .never, .yearly:
            comps.month = cal.component(.month, from: event.eventDate)
            comps.day   = cal.component(.day,   from: event.eventDate)
            if event.repeatRule == .never {
                comps.year = cal.component(.year, from: event.eventDate)
            }
        case .monthly:
            comps.day = cal.component(.day, from: event.eventDate)
        case .weekly:
            comps.weekday = cal.component(.weekday, from: event.eventDate)
        case .daily:
            break
        }
        return comps
    }
}
