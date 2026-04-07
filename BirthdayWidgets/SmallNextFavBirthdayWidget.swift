import WidgetKit
import SwiftUI

struct SmallNextFavProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmallBirthdayEntry {
        SmallBirthdayEntry(date: Date(), person: .placeholder, theme: .current())
    }

    func getSnapshot(in context: Context, completion: @escaping (SmallBirthdayEntry) -> Void) {
        let person = context.isPreview ? .placeholder : WidgetDataStore.nextFavBirthday()
        completion(SmallBirthdayEntry(date: Date(), person: person, theme: .current()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmallBirthdayEntry>) -> Void) {
        // Explicitly filter favorites only — nil if none exist
        let all = WidgetDataStore.load()
        let person = all.first(where: { $0.isFavorite == true })
        let entry = SmallBirthdayEntry(date: Date(), person: person, theme: .current())
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }
}

// MARK: - Redesigned small fav widget

struct SmallNextFavBirthdayView: View {
    let entry: SmallBirthdayEntry

    var t: WidgetTheme { entry.theme }

    var body: some View {
        if let person = entry.person {
            filledView(person)
        } else {
            emptyView
        }
    }

    private func filledView(_ person: WidgetPerson) -> some View {
        VStack(alignment: .center, spacing: 0) {
            // Header row: ⭐ FAVORITES  |  "Next month"
            HStack(alignment: .center) {
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(t.favTint)
                    Text("Fav")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(t.favTint)
                }
                Spacer()
                Text(timeLabel(person.daysUntilBirthday))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(t.textSecondary)
            }

            Spacer()

            // Big avatar
            WidgetAvatarView(person: person, size: 76, theme: t)

            Spacer()

            // Name + date
            Text(person.name)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(t.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(formattedDate(person))
                .font(.system(size: 11))
                .foregroundStyle(t.textSecondary)
                .padding(.top, 1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            WidgetBackground(theme: t)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 6) {
            Text("⭐").font(.system(size: 28))
            Text(L10n.Widget.noFavorites)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(t.textPrimary)
                .multilineTextAlignment(.center)
            Text(L10n.Widget.noFavoritesSub)
                .font(.system(size: 9))
                .foregroundStyle(t.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            WidgetBackground(theme: t)
        }
    }

    private func timeLabel(_ days: Int) -> String {
        switch days {
        case 0:       return "Today 🎉"
        case 1:       return "Tomorrow"
        case 2...30:  return "In \(days) days"
        default:      return "\(days) days"
        }
    }

    private func formattedDate(_ person: WidgetPerson) -> String {
        var comps = DateComponents()
        comps.month = person.birthdayMonth
        comps.day = person.birthdayDay
        comps.year = 2000 // arbitrary leap year for formatting
        guard let date = Calendar.current.date(from: comps) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: date)
    }
}

// MARK: - Widget

struct SmallNextFavBirthdayWidget: Widget {
    let kind = "SmallNextFavBirthday"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SmallNextFavProvider()) { entry in
            SmallNextFavBirthdayView(entry: entry)
        }
        .configurationDisplayName("Next Fav Birthday")
        .description("Shows the next birthday among your favorite people.")
        .supportedFamilies([.systemSmall])
    }
}
