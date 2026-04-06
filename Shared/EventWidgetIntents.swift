import AppIntents
import WidgetKit

// MARK: - Entity

/// Represents a single CountdownEvent for AppIntents widget configuration.
struct WidgetEventEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Event")
    static var defaultQuery = WidgetEventEntityQuery()

    var id: UUID
    var title: String
    var icon: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(icon) \(title)")
    }
}

// MARK: - Query

struct WidgetEventEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [WidgetEventEntity] {
        let events = WidgetDataStore.loadEvents()
        print("[EntityQuery] entities(for: \(identifiers)) from \(events.count) total")
        let result = events
            .filter { identifiers.contains($0.id) }
            .map { WidgetEventEntity(id: $0.id, title: $0.title, icon: $0.icon) }
        print("[EntityQuery] returning \(result.count) entities")
        return result
    }

    func suggestedEntities() async throws -> [WidgetEventEntity] {
        let events = WidgetDataStore.loadEvents()
        print("[EntityQuery] suggestedEntities: \(events.count) events")
        return events.map { WidgetEventEntity(id: $0.id, title: $0.title, icon: $0.icon) }
    }
}

// MARK: - Single-event intent

struct SelectEventIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Select Event"
    static let description = IntentDescription("Choose which event to display.")

    @Parameter(title: "Event")
    var event: WidgetEventEntity?
}

// MARK: - Two-event intent

struct SelectTwoEventsIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Select Events"
    static let description = IntentDescription("Choose two events to display side by side.")

    @Parameter(title: "First Event")
    var event1: WidgetEventEntity?

    @Parameter(title: "Second Event")
    var event2: WidgetEventEntity?
}
