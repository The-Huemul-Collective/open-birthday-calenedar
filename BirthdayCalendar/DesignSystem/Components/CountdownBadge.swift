import SwiftUI

/// Pill badge showing days remaining (or a cake for today).
struct CountdownBadge: View {
    let days: Int
    let theme: any AppTheme

    var body: some View {
        Group {
            if days == 0 {
                Text("🎂")
                    .font(.system(size: 22))
            } else {
                VStack(spacing: 0) {
                    Text("\(days)")
                        .font(BPFont.countdown())
                        .foregroundStyle(theme.badgeText)
                    Text(days == 1 ? "day" : "days")
                        .font(BPFont.captionBold())
                        .foregroundStyle(theme.badgeText.opacity(0.8))
                }
                .padding(.horizontal, BPSpacing.sm)
                .padding(.vertical, BPSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: BPRadius.md)
                        .fill(theme.badgeBackground)
                )
            }
        }
    }
}
