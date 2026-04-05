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

// MARK: - Distinct view with ⭐ header

struct SmallNextFavBirthdayView: View {
    let entry: SmallBirthdayEntry

    var t: WidgetTheme { entry.theme }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header badge
            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(t.favTint)
                Text(L10n.Widget.favorites)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(t.favTint)
                    .tracking(0.5)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 4)

            if let person = entry.person {
                // Reuse hero content inline
                VStack(alignment: .leading, spacing: 4) {
                    WidgetAvatarView(person: person, size: 34, theme: t)

                    Spacer()

                    Text(person.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(t.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(person.ageDisplay)
                        .font(.system(size: 10))
                        .foregroundStyle(t.textSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        if person.daysUntilBirthday == 0 {
                            Text(L10n.Widget.todayBirthday)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(t.accent)
                        } else {
                            Text("\(person.daysUntilBirthday)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(t.textPrimary)
                            Text(L10n.Birthday.days)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(t.textSecondary)
                                .padding(.bottom, 2)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            } else {
                // No favorites yet
                VStack(spacing: 4) {
                    Text("⭐")
                        .font(.system(size: 28))
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
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            WidgetBackground(theme: t)
        }
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
