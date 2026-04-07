import WidgetKit
import SwiftUI

// MARK: - Entry

struct MediumBirthdayEntry: TimelineEntry {
    let date: Date
    let next: WidgetPerson?        // nil = no data
    let upcoming: [WidgetPerson]   // next 3 after `next`
    let theme: WidgetTheme
}

// MARK: - Provider

struct MediumNextBirthdayProvider: TimelineProvider {
    func placeholder(in context: Context) -> MediumBirthdayEntry {
        MediumBirthdayEntry(
            date: Date(),
            next: .placeholder,
            upcoming: Array(WidgetPerson.previewList.dropFirst().prefix(3)),
            theme: .current()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MediumBirthdayEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : makeEntry(favOnly: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MediumBirthdayEntry>) -> Void) {
        let entry = makeEntry(favOnly: false)
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    func makeEntry(favOnly: Bool) -> MediumBirthdayEntry {
        let all = WidgetDataStore.load()
        let list = favOnly ? all.filter(\.isFavorite) : all
        return MediumBirthdayEntry(
            date: Date(),
            next: list.first,
            upcoming: Array(list.dropFirst().prefix(3)),
            theme: .current()
        )
    }
}

// MARK: - View

struct MediumNextBirthdayView: View {
    let entry: MediumBirthdayEntry

    var t: WidgetTheme { entry.theme }

    var body: some View {
        HStack(spacing: 0) {
            // LEFT: hero — next birthday (62%)
            WidgetHeroView(person: entry.next, theme: t)
                .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(t.divider)
                .frame(width: 1)
                .padding(.vertical, 10)
                .padding(.horizontal, 6)

            // RIGHT: upcoming list (38%)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 3) {
                    Image(systemName: "calendar")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(t.textSecondary)
                    Text(L10n.Widget.comingUp)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(t.textSecondary)
                        .tracking(0.4)
                }
                .padding(.top, 10)

                if entry.upcoming.isEmpty {
                    Spacer()
                    Text("No more\nbirthdays soon")
                        .font(.system(size: 10))
                        .foregroundStyle(t.textSecondary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(entry.upcoming) { person in
                            WidgetCompactRow(person: person, theme: t)
                        }
                    }
                    .padding(.top, 8)
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(0)
        }
        .containerBackground(for: .widget) {
            WidgetBackground(theme: t)
        }
    }
}

// MARK: - Widget

struct MediumNextBirthdayWidget: Widget {
    let kind = "MediumNextBirthday"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MediumNextBirthdayProvider()) { entry in
            MediumNextBirthdayView(entry: entry)
        }
        .configurationDisplayName("Next Birthday + Upcoming")
        .description("Shows the next birthday and 3 upcoming ones.")
        .supportedFamilies([.systemMedium])
    }
}
