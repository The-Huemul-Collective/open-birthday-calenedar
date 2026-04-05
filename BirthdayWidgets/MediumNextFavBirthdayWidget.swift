import WidgetKit
import SwiftUI

struct MediumNextFavProvider: TimelineProvider {
    func placeholder(in context: Context) -> MediumBirthdayEntry {
        MediumBirthdayEntry(
            date: Date(),
            next: .placeholder,
            upcoming: Array(WidgetPerson.previewList.dropFirst().prefix(3)),
            theme: .current()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MediumBirthdayEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MediumBirthdayEntry>) -> Void) {
        let entry = makeEntry()
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func makeEntry() -> MediumBirthdayEntry {
        let favs = WidgetDataStore.load().filter(\.isFavorite)
        return MediumBirthdayEntry(
            date: Date(),
            next: favs.first,
            upcoming: Array(favs.dropFirst().prefix(3)),
            theme: .current()
        )
    }
}

struct MediumNextFavBirthdayWidget: Widget {
    let kind = "MediumNextFavBirthday"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MediumNextFavProvider()) { entry in
            MediumNextBirthdayView(entry: entry)
        }
        .configurationDisplayName("Next Fav + Upcoming Favs")
        .description("Shows the next fav birthday and 3 upcoming fav birthdays.")
        .supportedFamilies([.systemMedium])
    }
}
