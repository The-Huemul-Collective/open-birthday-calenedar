import UserNotifications
import Foundation

final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Schedule

    /// Reschedules all notifications for a person based on current settings.
    func scheduleNotifications(for person: Person, settings: AppSettings) async {
        // Remove any existing notifications for this person first
        await removeNotifications(for: person)

        guard person.notificationsEnabled else { return }

        let hour   = settings.reminderHour
        let minute = settings.reminderMinute

        // Same-day notification (everyone)
        await scheduleAnnual(
            id: notificationID(person: person, kind: "sameday"),
            title: "🎂 \(person.name)'s Birthday!",
            body: sameDayBody(for: person),
            month: person.birthdayMonth,
            day: person.birthdayDay,
            hour: hour,
            minute: minute
        )

        // Early reminder for favorites
        if person.isFavorite {
            let earlyDays = settings.favEarlyReminderDays
            if let earlyDate = daysBeforeBirthday(
                month: person.birthdayMonth,
                day: person.birthdayDay,
                daysAhead: earlyDays
            ) {
                let cal = Calendar.current
                let earlyMonth = cal.component(.month, from: earlyDate)
                let earlyDay   = cal.component(.day, from: earlyDate)

                await scheduleAnnual(
                    id: notificationID(person: person, kind: "early"),
                    title: "⭐ \(person.name)'s Birthday in \(earlyDays) days!",
                    body: earlyBody(for: person, days: earlyDays),
                    month: earlyMonth,
                    day: earlyDay,
                    hour: hour,
                    minute: minute
                )
            }
        }
    }

    func removeNotifications(for person: Person) async {
        let ids = [
            notificationID(person: person, kind: "sameday"),
            notificationID(person: person, kind: "early"),
        ]
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Private helpers

    private func scheduleAnnual(
        id: String,
        title: String,
        body: String,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int
    ) async {
        var comps = DateComponents()
        comps.month  = month
        comps.day    = day
        comps.hour   = hour
        comps.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private func notificationID(person: Person, kind: String) -> String {
        "birthday.\(person.id.uuidString).\(kind)"
    }

    private func sameDayBody(for person: Person) -> String {
        if let age = person.turningAge {
            return "\(person.name) turns \(age) today. Don't forget to wish them!"
        }
        return "Today is \(person.name)'s birthday. Don't forget to wish them!"
    }

    private func earlyBody(for person: Person, days: Int) -> String {
        "\(person.name)'s birthday is coming up in \(days) days. Plan something special!"
    }

    private func daysBeforeBirthday(month: Int, day: Int, daysAhead: Int) -> Date? {
        let cal = Calendar.current
        let now = Date()
        let year = cal.component(.year, from: now)

        var comps = DateComponents()
        comps.year  = year
        comps.month = month
        comps.day   = day

        guard var bday = cal.date(from: comps) else { return nil }
        if bday < now {
            comps.year = year + 1
            bday = cal.date(from: comps) ?? bday
        }
        return cal.date(byAdding: .day, value: -daysAhead, to: bday)
    }
}
