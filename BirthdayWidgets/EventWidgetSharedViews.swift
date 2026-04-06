import SwiftUI
import WidgetKit

// MARK: - Friend avatar stack

/// Overlapping avatar stack showing friends linked to an event.
struct WidgetFriendAvatarStack: View {
    let friendIDs: [String]
    let theme: WidgetTheme
    var size: CGFloat = 18

    private var friends: [WidgetPerson] {
        let all = WidgetDataStore.load()
        return friendIDs
            .compactMap { idStr in all.first { $0.id.uuidString == idStr } }
            .prefix(3)
            .reversed()  // so first friend appears on top visually
    }

    var body: some View {
        HStack(spacing: -(size * 0.35)) {
            ForEach(Array(friends.enumerated()), id: \.offset) { i, person in
                WidgetAvatarView(person: person, size: size, theme: theme)
                    .zIndex(Double(i))
            }
        }
    }
}

// MARK: - Background

/// Resolves the widget's background: photo (with dark overlay) or theme gradient.
struct EventWidgetBackground: View {
    let event: WidgetEvent?
    let theme: WidgetTheme

    var body: some View {
        if let event, let img = WidgetDataStore.eventImage(for: event) {
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
        } else {
            WidgetBackground(theme: theme)
        }
    }
}

// MARK: - Helpers

/// Resolves the text color for an event: custom hex → white (if photo) → theme primary.
func eventTextColor(_ event: WidgetEvent, theme: WidgetTheme) -> Color {
    if let hex = event.textColorHex, let c = Color(hex: hex) { return c }
    if WidgetDataStore.eventImage(for: event) != nil { return .white }
    return theme.textPrimary
}

/// Resolves the number/accent color for an event: custom hex → white (if photo) → theme accent.
func eventAccentColor(_ event: WidgetEvent, theme: WidgetTheme) -> Color {
    if let hex = event.textColorHex, let c = Color(hex: hex) { return c }
    if WidgetDataStore.eventImage(for: event) != nil { return .white }
    return theme.accent
}

/// Finds the event the user configured (or falls back to the first available).
func resolveEvent(_ intent: SelectEventIntent) -> WidgetEvent? {
    let events = WidgetDataStore.loadEvents()
    if let id = intent.event?.id {
        return events.first { $0.id == id } ?? events.first
    }
    return events.first
}
