import SwiftUI

struct EventRowView: View {
    let event: CountdownEvent
    let resolvedFriends: [Person]
    let theme: any AppTheme

    private var photoImage: UIImage? {
        event.photoData.flatMap { UIImage(data: $0) }
    }

    private var hasPhoto: Bool { photoImage != nil }

    private var labelColor: Color {
        if let hex = event.textColorHex, let custom = Color(hex: hex) { return custom }
        return hasPhoto ? .white : theme.textPrimary
    }

    private var badgeColor: Color {
        if let hex = event.textColorHex, let custom = Color(hex: hex) { return custom }
        return hasPhoto ? .white : theme.badgeText
    }

    var body: some View {
        HStack(spacing: BPSpacing.md) {
            iconSquare
            info
            Spacer()
            VStack(alignment: .trailing, spacing: BPSpacing.xs) {
                badge
                if !resolvedFriends.isEmpty {
                    FriendAvatarStack(
                        friends: resolvedFriends,
                        size: 20,
                        theme: theme,
                        maxVisible: 3
                    )
                }
            }
        }
        .padding(.horizontal, BPSpacing.lg)
        .padding(.vertical, BPSpacing.md)
        .background {
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: BPRadius.lg)
                        .fill(theme.cardBackground)
                    if let img = photoImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                        Color.black.opacity(0.45)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: BPRadius.lg))
            }
        }
        .padding(.horizontal, BPSpacing.lg)
    }

    // MARK: - Sub-views

    private var iconSquare: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BPRadius.sm)
                .fill(hasPhoto ? AnyShapeStyle(Color.white.opacity(0.25)) : theme.badgeBackground)
                .frame(width: 46, height: 46)
            if !event.icon.isEmpty {
                Text(event.icon)
                    .font(.system(size: 24))
            }
        }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: BPSpacing.xxs) {
            Text(event.title)
                .font(BPFont.titleMedium())
                .foregroundStyle(labelColor)
                .lineLimit(1)
            Text(event.formattedDate)
                .font(BPFont.caption())
                .foregroundStyle(labelColor.opacity(0.7))
        }
    }

    @ViewBuilder
    private var badge: some View {
        if event.isEventToday {
            Text("🎉")
                .font(.system(size: 26))
        } else {
            let fg: Color = badgeColor
            VStack(spacing: 0) {
                Text(event.isCountingUp ? "+\(event.countdownValue)" : "\(event.countdownValue)")
                    .font(BPFont.countdown())
                    .foregroundStyle(fg)
                Text(event.isCountingUp ? "\(event.countdownLabel) ago" : event.countdownLabel)
                    .font(BPFont.captionBold())
                    .foregroundStyle(fg.opacity(0.8))
            }
            .padding(.horizontal, BPSpacing.sm)
            .padding(.vertical, BPSpacing.xs)
            .background {
                if !hasPhoto {
                    RoundedRectangle(cornerRadius: BPRadius.md)
                        .fill(theme.badgeBackground)
                }
            }
        }
    }
}
