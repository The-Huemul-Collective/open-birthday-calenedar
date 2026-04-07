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

                // Upcoming list (right ~45%)
                sideList
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .containerBackground(for: .widget) {
            WidgetBackground(theme: entry.theme)
        }
    }

    // MARK: - Main card (left)

    @ViewBuilder
    private var mainCard: some View {
        if let event = entry.mainEvent {
            let textColor = eventTextColor(event, theme: entry.theme)
            let numColor  = eventAccentColor(event, theme: entry.theme)
            ZStack {
                if let img = WidgetDataStore.eventImage(for: event) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [.black.opacity(0.65), .black.opacity(0.20), .black.opacity(0.55)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                }
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        if !event.icon.isEmpty { Text(event.icon).font(.system(size: 12)) }
                        Text(event.title)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(textColor)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Text("\(event.countdownValue)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(numColor)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(event.countdownLabel)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(textColor.opacity(0.85))
                        Text(event.shortFormattedDate)
                            .font(.system(size: 9))
                            .foregroundStyle(textColor.opacity(0.70))
                    }
                    if !event.friendIDs.isEmpty {
                        WidgetFriendAvatarStack(friendIDs: event.friendIDs, theme: entry.theme, size: 16)
                            .padding(.top, 0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
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
        VStack(alignment: .leading, spacing: 0) {
            if entry.otherEvents.isEmpty {
                VStack {
                    Text(L10n.EventWidget.noMore)
                        .font(.system(size: 10))
                        .foregroundStyle(entry.theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(Array(entry.otherEvents.prefix(3).enumerated()), id: \.offset) { i, event in
                    DashboardCompactRow(event: event, theme: entry.theme)
                    if i < entry.otherEvents.prefix(3).count - 1 {
                        Rectangle()
                            .fill(entry.theme.divider)
                            .frame(height: 1)
                            .padding(.horizontal, 0)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 0)
    }
}

// MARK: - Compact row

private struct DashboardCompactRow: View {
    let event: WidgetEvent
    let theme: WidgetTheme

    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 3) {
                    if !event.icon.isEmpty { Text(event.icon).font(.system(size: 10)) }
                    Text(event.title)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                }
                Text(event.shortFormattedDate)
                    .font(.system(size: 9))
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(event.countdownValue)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.accent)
                Text(event.countdownLabel)
                    .font(.system(size: 8))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .padding(0)
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
