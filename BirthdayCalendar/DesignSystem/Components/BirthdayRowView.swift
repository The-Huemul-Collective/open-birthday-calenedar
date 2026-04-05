import SwiftUI

/// A single row in the birthday list.
struct BirthdayRowView: View {
    let person: Person
    let theme: any AppTheme

    var body: some View {
        HStack(spacing: BPSpacing.md) {
            AvatarView(person: person, size: 52, theme: theme)

            VStack(alignment: .leading, spacing: BPSpacing.xxs) {
                HStack(spacing: BPSpacing.xs) {
                    Text(person.name)
                        .font(BPFont.titleMedium())
                        .foregroundStyle(theme.textPrimary)
                    if person.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(theme.favoriteTint)
                    }
                }

                Text(person.ageDisplay)
                    .font(BPFont.bodyMedium())
                    .foregroundStyle(theme.textSecondary)

                Text(birthdayString)
                    .font(BPFont.caption())
                    .foregroundStyle(theme.textTertiary)
            }

            Spacer()

            CountdownBadge(days: person.daysUntilBirthday, theme: theme)
        }
        .padding(.horizontal, BPSpacing.lg)
        .padding(.vertical, BPSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BPRadius.lg)
                .fill(theme.cardBackground)
        )
        .padding(.horizontal, BPSpacing.lg)
    }

    private var birthdayString: String {
        let months = ["Jan","Feb","Mar","Apr","May","Jun",
                      "Jul","Aug","Sep","Oct","Nov","Dec"]
        let monthStr = months[person.birthdayMonth - 1]
        return "\(monthStr) \(person.birthdayDay)"
    }
}
