import SwiftUI

/// Inline mini-widget card shown at the top of the event form.
struct EventWidgetPreview: View {
    let icon: String
    let title: String
    let eventDate: Date
    let hasTime: Bool
    let countdownValue: Int
    let countdownLabel: String
    let isPast: Bool
    let isToday: Bool
    let photoData: Data?
    let textColorHex: String?
    let friends: [Person]
    let theme: any AppTheme

    private static let size: CGFloat = 148

    private var photoImage: UIImage? {
        photoData.flatMap { UIImage(data: $0) }
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Background: always a filled shape first
            RoundedRectangle(cornerRadius: BPRadius.xl)
                .fill(theme.badgeBackground)

            // Photo overlay — constrained to widget bounds
            if let img = photoImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.size, height: Self.size)
                    .clipped()
                Color.black.opacity(0.45)
            }

            // Content
            VStack(alignment: .leading, spacing: BPSpacing.xxs) {
                HStack(spacing: BPSpacing.xs) {
                    if !icon.isEmpty {
                        Text(icon)
                            .font(.system(size: 16))
                    }
                    Text(title.isEmpty ? "Event title" : title)
                        .font(BPFont.captionBold())
                        .foregroundStyle(labelColor.opacity(0.9))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if isToday {
                    Text("🎉")
                        .font(.system(size: 48))
                } else {
                    Text(isPast ? "+\(countdownValue)" : "\(countdownValue)")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundStyle(labelColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                if !isToday {
                    Text(isPast ? "\(countdownLabel) ago" : countdownLabel)
                        .font(BPFont.captionBold())
                        .foregroundStyle(labelColor.opacity(0.75))
                }

                HStack(alignment: .bottom) {
                    Text(shortDate)
                        .font(BPFont.caption())
                        .foregroundStyle(labelColor.opacity(0.6))
                    Spacer(minLength: 0)
                    if !friends.isEmpty {
                        FriendAvatarStack(
                            friends: friends,
                            size: 22,
                            theme: theme,
                            maxVisible: 3
                        )
                    }
                }
            }
            .padding(BPSpacing.md)
        }
        .frame(width: Self.size, height: Self.size)
        .clipShape(RoundedRectangle(cornerRadius: BPRadius.xl))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    private var labelColor: Color {
        if let hex = textColorHex, let custom = Color(hex: hex) { return custom }
        return photoData != nil ? .white : theme.badgeText
    }

    private var shortDate: String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = hasTime ? .short : .none
        return f.string(from: eventDate)
    }
}
