import SwiftUI

/// Overlapping circular avatars for a list of friends. Shows up to `maxVisible`,
/// then a "+N" bubble for the rest.
struct FriendAvatarStack: View {
    let friends: [Person]
    let size: CGFloat
    let theme: any AppTheme
    var maxVisible: Int = 3

    private var visible: [Person] { Array(friends.prefix(maxVisible)) }
    private var overflow: Int { max(0, friends.count - maxVisible) }
    private let overlap: CGFloat = 0.35   // fraction of size to overlap

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(visible.enumerated()), id: \.element.id) { i, person in
                AvatarView(person: person, size: size, theme: theme)
                    .offset(x: CGFloat(i) * -(size * overlap))
                    .zIndex(Double(visible.count - i))
            }
            if overflow > 0 {
                overflowBubble
                    .offset(x: CGFloat(visible.count) * -(size * overlap))
            }
        }
        // pull the stack left to compensate for offsets
        .padding(.trailing, CGFloat(visible.count - 1) * -(size * overlap))
    }

    private var overflowBubble: some View {
        ZStack {
            Circle()
                .fill(theme.badgeBackground)
                .frame(width: size + 3, height: size + 3)
            Text("+\(overflow)")
                .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.badgeText)
        }
    }
}
