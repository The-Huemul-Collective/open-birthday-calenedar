import Foundation
import UIKit

/// Reads and writes the shared JSON file inside the App Group container.
/// The main app writes after every change; widgets read on timeline refresh.
struct WidgetDataStore {
    static let appGroupID = "group.com.open.birthdaycalendar"
    private static let fileName = "widget_people.json"

    static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }

    static func save(_ people: [WidgetPerson]) {
        guard let url = fileURL else { return }
        let sorted = people.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }
        if let data = try? JSONEncoder().encode(sorted) {
            try? data.write(to: url, options: .atomic)
        }
    }

    static func load() -> [WidgetPerson] {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url),
              let people = try? JSONDecoder().decode([WidgetPerson].self, from: data)
        else { return [] }
        return people.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }
    }

    static func nextBirthday() -> WidgetPerson? {
        load().first
    }

    static func nextFavBirthday() -> WidgetPerson? {
        load().first(where: \.isFavorite)
    }

    static func upcoming(_ count: Int, favOnly: Bool = false) -> [WidgetPerson] {
        let all = load()
        let filtered = favOnly ? all.filter(\.isFavorite) : all
        return Array(filtered.prefix(count))
    }

    /// Loads a saved contact photo from the App Group container.
    static func image(for person: WidgetPerson) -> UIImage? {
        guard let fileName = person.photoFileName,
              let url = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
                .appendingPathComponent(fileName),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Events

    private static let eventFileName = "widget_events.json"

    static var eventFileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(eventFileName)
    }

    static func saveEvents(_ events: [WidgetEvent]) {
        guard let url = eventFileURL else { return }
        if let data = try? JSONEncoder().encode(events) {
            try? data.write(to: url, options: .atomic)
        }
    }

    static func loadEvents() -> [WidgetEvent] {
        guard let url = eventFileURL,
              let data = try? Data(contentsOf: url),
              let events = try? JSONDecoder().decode([WidgetEvent].self, from: data)
        else { return [] }
        return events.sorted { $0.daysUntilEvent < $1.daysUntilEvent }
    }

    /// Loads an event's photo frame from the App Group container.
    static func eventImage(for event: WidgetEvent) -> UIImage? {
        guard let fileName = event.photoFileName,
              let url = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
                .appendingPathComponent(fileName),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return UIImage(data: data)
    }
}
