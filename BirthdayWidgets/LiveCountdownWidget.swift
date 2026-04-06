import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Provider (reuses EventCountdownEntry)

struct LiveCountdownProvider: AppIntentTimelineProvider {
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
        // Text(.timer) handles live HH:MM:SS updates; we only need daily refresh for the days count.
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        return Timeline(entries: [entry], policy: .after(midnight))
    }
}

// MARK: - View

struct LiveCountdownView: View {
    let entry: EventCountdownEntry

    var body: some View {
        Group {
            if let event = entry.event { liveContent(event) } else { noEventContent }
        }
        .containerBackground(for: .widget) {
            EventWidgetBackground(event: entry.event, theme: entry.theme)
        }
    }

    private func liveContent(_ event: WidgetEvent) -> some View {
        let color = eventTextColor(event, theme: entry.theme)
        let days  = event.secondsBasedDays
        return VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(alignment: .center) {
                if !event.icon.isEmpty { Text(event.icon).font(.system(size: 13)) }
                Text(event.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                if event.notificationsEnabled {
                    Image(systemName: "alarm")
                        .font(.system(size: 14))
                        .foregroundStyle(color.opacity(0.75))
                }
            }
            Text(event.shortFormattedDate)
                .font(.system(size: 10))
                .foregroundStyle(color.opacity(0.65))
                .padding(.top, 2)

            Spacer(minLength: 0)

            // D : HH:MM:SS
            // Text(.timer) on subDayTimerDate gives a live HH:MM:SS that the system
            // updates every second without needing rapid timeline entries.
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(days)")
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                Text(":")
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(color.opacity(0.45))
                Text(event.subDayTimerDate, style: .timer)
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .minimumScaleFactor(0.45)
                    .lineLimit(1)
            }

            // Column labels
            HStack(spacing: 0) {
                Text(L10n.EventWidget.days)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(color.opacity(0.55))
                Spacer()
                Text("\(L10n.EventWidget.hrs)   \(L10n.EventWidget.min)   \(L10n.EventWidget.sec)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(color.opacity(0.55))
            }
            .padding(.top, 3)

            // Friend avatars
            if !event.friendIDs.isEmpty {
                HStack {
                    Spacer()
                    WidgetFriendAvatarStack(friendIDs: event.friendIDs, theme: entry.theme, size: 16)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
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

struct LiveCountdownWidget: Widget {
    let kind = "LiveCountdown"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectEventIntent.self,
            provider: LiveCountdownProvider()
        ) { entry in
            LiveCountdownView(entry: entry)
        }
        .configurationDisplayName(L10n.EventWidget.liveCountdown)
        .description(L10n.EventWidget.liveCountdownDesc)
        .supportedFamilies([.systemMedium])
    }
}
