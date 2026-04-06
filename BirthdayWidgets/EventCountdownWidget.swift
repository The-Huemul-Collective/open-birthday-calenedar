import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Entry

struct EventCountdownEntry: TimelineEntry {
    let date: Date
    let event: WidgetEvent?
    let theme: WidgetTheme
}

// MARK: - Provider

struct EventCountdownProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> EventCountdownEntry {
        EventCountdownEntry(date: Date(), event: .placeholder, theme: .current())
    }

    func snapshot(for configuration: SelectEventIntent, in context: Context) async -> EventCountdownEntry {
        let event = context.isPreview ? .placeholder : resolveEvent(configuration)
        return EventCountdownEntry(date: Date(), event: event, theme: .current())
    }

    func timeline(for configuration: SelectEventIntent, in context: Context) async -> Timeline<EventCountdownEntry> {
        let event = resolveEvent(configuration)
        let entry = EventCountdownEntry(date: Date(), event: event, theme: .current())
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        return Timeline(entries: [entry], policy: .after(midnight))
    }
}

// MARK: - View

struct EventCountdownView: View {
    let entry: EventCountdownEntry

    var body: some View {
        Group {
            if let event = entry.event {
                eventContent(event)
            } else {
                noEventContent
            }
        }
        .containerBackground(for: .widget) {
            EventWidgetBackground(event: entry.event, theme: entry.theme)
        }
    }

    private func eventContent(_ event: WidgetEvent) -> some View {
        let color = eventTextColor(event, theme: entry.theme)
        return VStack(alignment: .leading, spacing: 0) {
            // Title row
            HStack(spacing: 4) {
                if !event.icon.isEmpty {
                    Text(event.icon).font(.system(size: 14))
                }
                Text(event.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 4)

            // Big number
            Text("\(event.countdownValue)")
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            // Bottom: unit + date on left; avatars on right
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(event.countdownLabel)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(color.opacity(0.85))
                    Text(event.shortFormattedDate)
                        .font(.system(size: 10))
                        .foregroundStyle(color.opacity(0.70))
                }
                Spacer()
                if !event.friendIDs.isEmpty {
                    WidgetFriendAvatarStack(friendIDs: event.friendIDs, theme: entry.theme, size: 28)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(8)
    }

    private var noEventContent: some View {
        VStack(spacing: 6) {
            Text("⏱️").font(.system(size: 28))
            Text(L10n.EventWidget.noEvent)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(entry.theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(L10n.EventWidget.noEventSub)
                .font(.system(size: 10))
                .foregroundStyle(entry.theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
    }
}

// MARK: - Widget

struct EventCountdownWidget: Widget {
    let kind = "EventCountdown"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectEventIntent.self,
            provider: EventCountdownProvider()
        ) { entry in
            EventCountdownView(entry: entry)
        }
        .configurationDisplayName(L10n.EventWidget.countdown)
        .description(L10n.EventWidget.countdownDesc)
        .supportedFamilies([.systemSmall])
    }
}
