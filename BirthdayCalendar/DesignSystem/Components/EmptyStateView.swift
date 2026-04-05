import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let theme: any AppTheme

    var body: some View {
        VStack(spacing: BPSpacing.lg) {
            Text(icon)
                .font(.system(size: 56))
            Text(title)
                .font(BPFont.titleLarge())
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(BPFont.bodyMedium())
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BPSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
