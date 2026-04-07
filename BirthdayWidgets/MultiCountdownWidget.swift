import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Entry

struct MultiEventEntry: TimelineEntry {
    let date: Date
    let event1: WidgetEvent?
    let event2: WidgetEvent?
    let theme: WidgetTheme
}

// MARK: - Provider

struct MultiCountdownProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MultiEventEntry {
        MultiEventEntry(date: Date(), event1: .placeholder, event2: .placeholder2, theme: .current())
    }

    func snapshot(for configuration: SelectTwoEventsIntent, in context: Context) async -> MultiEventEntry {
        if context.isPreview {
            return MultiEventEntry(date: Date(), event1: .placeholder, event2: .placeholder2, theme: .current())
        }
        let (e1, e2) = resolveTwo(configuration)
        return MultiEventEntry(date: Date(), event1: e1, event2: e2, theme: .current())
    }

    func timeline(for configuration: SelectTwoEventsIntent, in context: Context) async -> Timeline<MultiEventEntry> {
        let (e1, e2) = resolveTwo(configuration)
        let entry = MultiEventEntry(date: Date(), event1: e1, event2: e2, theme: .current())
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        return Timeline(entries: [entry], policy: .after(midnight))
    }

    private func resolveTwo(_ intent: SelectTwoEventsIntent) -> (WidgetEvent?, WidgetEvent?) {
        let events = WidgetDataStore.loadEvents()
        let e1: WidgetEvent?
        if let id = intent.event1?.id { e1 = events.first { $0.id == id } } else { e1 = events.first }
        let e2: WidgetEvent?
        if let id = intent.event2?.id {
            e2 = events.first { $0.id == id }
        } else {
            e2 = events.dropFirst().first
        }
        return (e1, e2)
    }
}

// MARK: - Half card

private struct EventHalfCard: View {
    let event: WidgetEvent?
    let theme: WidgetTheme
    var onPhoto: Bool = false   // true when widget has a global photo background

    var body: some View {
        if let event { filledCard(event) } else { emptyCard }
    }

    private func filledCard(_ event: WidgetEvent) -> some View {
        let textColor: Color = onPhoto ? .white : eventTextColor(event, theme: theme)
        let numColor:  Color = onPhoto ? .white : eventAccentColor(event, theme: theme)
        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                if !event.icon.isEmpty { Text(event.icon).font(.system(size: 12)) }
                Text(event.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            Text("\(event.countdownValue)")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(numColor)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(event.countdownLabel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(textColor.opacity(0.85))
                    Text(event.shortFormattedDate)
                        .font(.system(size: 9))
                        .foregroundStyle(textColor.opacity(0.70))
                }
                Spacer()
                if !event.friendIDs.isEmpty {
                    WidgetFriendAvatarStack(friendIDs: event.friendIDs, theme: theme, size: 22)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(10)
    }

    private var emptyCard: some View {
        VStack(spacing: 4) {
            Text(L10n.EventWidget.noEvent)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(onPhoto ? .white : theme.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - View

struct MultiCountdownView: View {
    let entry: MultiEventEntry

    private var hasPhoto: Bool {
        entry.event1.flatMap { WidgetDataStore.eventImage(for: $0) } != nil
    }

    var body: some View {
        HStack(spacing: 0) {
            EventHalfCard(event: entry.event1, theme: entry.theme, onPhoto: hasPhoto)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Rectangle()
                .fill(hasPhoto ? Color.white.opacity(0.25) : entry.theme.divider)
                .frame(width: 1)
                .padding(.vertical, 10)
                .padding(.horizontal, 4)

            EventHalfCard(event: entry.event2, theme: entry.theme, onPhoto: hasPhoto)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .containerBackground(for: .widget) {
            EventWidgetBackground(event: entry.event1, theme: entry.theme)
        }
    }
}

// MARK: - Widget

struct MultiCountdownWidget: Widget {
    let kind = "MultiCountdown"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectTwoEventsIntent.self,
            provider: MultiCountdownProvider()
        ) { entry in
            MultiCountdownView(entry: entry)
        }
        .configurationDisplayName(L10n.EventWidget.multiCountdown)
        .description(L10n.EventWidget.multiCountdownDesc)
        .supportedFamilies([.systemMedium])
    }
}
