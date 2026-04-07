import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Entry

struct DashboardEntry: TimelineEntry {
    let date: Date
    let mainEvent: WidgetEvent?
    let otherEvents: [WidgetEvent]
    let theme: WidgetTheme
}

// MARK: - Provider

struct DashboardProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DashboardEntry {
        DashboardEntry(date: Date(), mainEvent: .placeholder, otherEvents: [.placeholder2], theme: .current())
    }

    func snapshot(for configuration: SelectEventIntent, in context: Context) async -> DashboardEntry {
        if context.isPreview {
            return DashboardEntry(date: Date(), mainEvent: .placeholder, otherEvents: [.placeholder2], theme: .current())
        }
        return resolve(configuration)
    }

    func timeline(for configuration: SelectEventIntent, in context: Context) async -> Timeline<DashboardEntry> {
        let entry = resolve(configuration)
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        return Timeline(entries: [entry], policy: .after(midnight))
    }

    private func resolve(_ intent: SelectEventIntent) -> DashboardEntry {
        let all = WidgetDataStore.loadEvents()
        let main: WidgetEvent?
        if let id = intent.event?.id { main = all.first { $0.id == id } } else { main = all.first }
        let others = all.filter { $0.id != main?.id }.prefix(3).map { $0 }
        return DashboardEntry(date: Date(), mainEvent: main, otherEvents: others, theme: .current())
    }
}

// MARK: - View

struct DashboardView: View {
    let entry: DashboardEntry

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // Main event (left ~55%)
                mainCard
                    .frame(width: geo.size.width * 0.55, height: geo.size.height)

                Rectangle()
                    .fill(entry.theme.divider)
                    .frame(width: 1)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)

                // Upcoming list (right ~45%)
                sideList
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .containerBackground(for: .widget) {
            EventWidgetBackground(event: entry.mainEvent, theme: entry.theme)
        }
    }

    // MARK: - Main card (left)

    private var hasPhoto: Bool {
        entry.mainEvent.flatMap { WidgetDataStore.eventImage(for: $0) } != nil
    }

    @ViewBuilder
    private var mainCard: some View {
        if let event = entry.mainEvent {
            let textColor: Color = hasPhoto ? .white : eventTextColor(event, theme: entry.theme)
            let numColor:  Color = hasPhoto ? .white : eventAccentColor(event, theme: entry.theme)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    if !event.icon.isEmpty { Text(event.icon).font(.system(size: 13)) }
                    Text(event.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(textColor)
                        .lineLimit(1)
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
                        WidgetFriendAvatarStack(friendIDs: event.friendIDs, theme: entry.theme, size: 22)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(10)
        } else {
            VStack(spacing: 6) {
                Text("⏱️").font(.system(size: 24))
                Text(L10n.EventWidget.noEvent)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(entry.theme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Side list (right)

    private var sideList: some View {
        let labelColor: Color = hasPhoto ? .white.opacity(0.7) : entry.theme.textSecondary
        return VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 3) {
                Image(systemName: "calendar")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(labelColor)
                Text(L10n.Widget.comingUp)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(labelColor)
                    .tracking(0.4)
            }
            .padding(.top, 10)
            .padding(.bottom, 6)

            if entry.otherEvents.isEmpty {
                Spacer()
                Text(L10n.EventWidget.noMore)
                    .font(.system(size: 10))
                    .foregroundStyle(entry.theme.textSecondary)
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
                ForEach(Array(entry.otherEvents.prefix(3).enumerated()), id: \.offset) { i, event in
                    DashboardCompactRow(event: event, theme: entry.theme, onPhoto: hasPhoto)
                    if i < entry.otherEvents.prefix(3).count - 1 {
                        Rectangle()
                            .fill(entry.theme.divider)
                            .frame(height: 1)
                            .padding(.horizontal, 4)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 6)
    }
}

// MARK: - Compact row

private struct DashboardCompactRow: View {
    let event: WidgetEvent
    let theme: WidgetTheme
    var onPhoto: Bool = false

    var body: some View {
        let primary: Color   = onPhoto ? .white : theme.textPrimary
        let secondary: Color = onPhoto ? .white.opacity(0.65) : theme.textSecondary
        let accent: Color    = onPhoto ? .white : theme.accent
        return HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 3) {
                    if !event.icon.isEmpty { Text(event.icon).font(.system(size: 10)) }
                    Text(event.title)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary)
                        .lineLimit(1)
                }
                Text(event.shortFormattedDate)
                    .font(.system(size: 9))
                    .foregroundStyle(secondary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(event.countdownValue)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                Text(event.countdownLabel)
                    .font(.system(size: 8))
                    .foregroundStyle(secondary)
            }
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Widget

struct DashboardWidget: Widget {
    let kind = "CountdownDashboard"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectEventIntent.self,
            provider: DashboardProvider()
        ) { entry in
            DashboardView(entry: entry)
        }
        .configurationDisplayName(L10n.EventWidget.dashboard)
        .description(L10n.EventWidget.dashboardDesc)
        .supportedFamilies([.systemMedium])
    }
}
