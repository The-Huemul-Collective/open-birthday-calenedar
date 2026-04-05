import WidgetKit
import SwiftUI

// MARK: - Entry

struct SmallBirthdayEntry: TimelineEntry {
    let date: Date
    let person: WidgetPerson?   // nil = no data yet
    let theme: WidgetTheme
}

// MARK: - Provider

struct SmallNextBirthdayProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmallBirthdayEntry {
        SmallBirthdayEntry(date: Date(), person: .placeholder, theme: .current())
    }

    func getSnapshot(in context: Context, completion: @escaping (SmallBirthdayEntry) -> Void) {
        // Use real data if available, preview placeholder only in gallery
        let person = context.isPreview ? .placeholder : WidgetDataStore.nextBirthday()
        completion(SmallBirthdayEntry(date: Date(), person: person, theme: .current()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmallBirthdayEntry>) -> Void) {
        let person = WidgetDataStore.nextBirthday()   // nil if app has no data
        let entry = SmallBirthdayEntry(date: Date(), person: person, theme: .current())
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }
}

// MARK: - View

struct SmallNextBirthdayView: View {
    let entry: SmallBirthdayEntry

    var body: some View {
        WidgetHeroView(person: entry.person, theme: entry.theme)
            .containerBackground(for: .widget) {
                WidgetBackground(theme: entry.theme)
            }
    }
}

// MARK: - Widget

struct SmallNextBirthdayWidget: Widget {
    let kind = "SmallNextBirthday"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SmallNextBirthdayProvider()) { entry in
            SmallNextBirthdayView(entry: entry)
        }
        .configurationDisplayName("Next Birthday")
        .description("Shows the next upcoming birthday.")
        .supportedFamilies([.systemSmall])
    }
}
