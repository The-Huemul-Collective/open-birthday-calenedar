import SwiftUI
import WidgetKit

// MARK: - Background helper

struct WidgetBackground: View {
    let theme: WidgetTheme

    var body: some View {
        LinearGradient(
            colors: [theme.backgroundStart, theme.backgroundEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Avatar (photo > emoji > cake)

struct WidgetAvatarView: View {
    let person: WidgetPerson
    let size: CGFloat
    let theme: WidgetTheme

    var body: some View {
        Group {
            if let uiImage = WidgetDataStore.image(for: person) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let emoji = person.photoEmoji {
                ZStack {
                    Circle()
                        .fill(theme.cardFill.opacity(theme.cardOpacity + 0.1))
                    Text(emoji)
                        .font(.system(size: size * 0.5))
                }
                .frame(width: size, height: size)
            } else {
                ZStack {
                    Circle()
                        .fill(theme.cardFill.opacity(theme.cardOpacity + 0.1))
                    Text("🎂")
                        .font(.system(size: size * 0.5))
                }
                .frame(width: size, height: size)
            }
        }
        .overlay(Circle().strokeBorder(theme.accent.opacity(0.5), lineWidth: 1.5))
    }
}

// MARK: - Hero cell (big "next birthday" card, right side of medium or full small)

struct WidgetHeroView: View {
    let person: WidgetPerson?
    let theme: WidgetTheme

    var body: some View {
        if let person {
            filledHero(person)
        } else {
            emptyHero
        }
    }

    private func filledHero(_ person: WidgetPerson) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                WidgetAvatarView(person: person, size: 36, theme: theme)
                Spacer()
                if person.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.favTint)
                }
            }

            Spacer()

            Text(person.name)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(person.ageDisplay)
                .font(.system(size: 11))
                .foregroundStyle(theme.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                if person.daysUntilBirthday == 0 {
                    Text(L10n.Widget.todayBirthday)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accent)
                } else {
                    Text("\(person.daysUntilBirthday)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                    Text(L10n.Birthday.days)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(theme.textSecondary)
                        .padding(.bottom, 2)
                }
            }
        }
        .padding(12)
    }

    private var emptyHero: some View {
        VStack(spacing: 6) {
            Text("🎂")
                .font(.system(size: 30))
            Text(L10n.Widget.empty)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
            Text(L10n.Widget.emptySubtitle)
                .font(.system(size: 10))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
    }
}

// MARK: - Compact row (sidebar of medium widgets)

struct WidgetCompactRow: View {
    let person: WidgetPerson
    let theme: WidgetTheme

    var body: some View {
        HStack(spacing: 6) {
            WidgetAvatarView(person: person, size: 22, theme: theme)

            VStack(alignment: .leading, spacing: 1) {
                Text(person.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                Text(daysLabel)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var daysLabel: String {
        let d = person.daysUntilBirthday
        if d == 0 { return L10n.Birthday.today }
        if d == 1 { return L10n.Birthday.tomorrow }
        return L10n.Birthday.inDays(d)
    }
}

// MARK: - Placeholder people (Xcode gallery preview only)

extension WidgetPerson {
    static let placeholder = WidgetPerson(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Alex Smith",
        birthdayDay: Calendar.current.component(.day, from: Date()) + 2,
        birthdayMonth: Calendar.current.component(.month, from: Date()),
        birthdayYear: 1990,
        photoEmoji: "🎉",
        photoFileName: nil,
        isFavorite: true
    )

    static let previewList: [WidgetPerson] = [
        placeholder,
        WidgetPerson(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Jordan", birthdayDay: 20, birthdayMonth: Calendar.current.component(.month, from: Date()), birthdayYear: nil, photoEmoji: "🌟", photoFileName: nil, isFavorite: false),
        WidgetPerson(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Casey", birthdayDay: 28, birthdayMonth: Calendar.current.component(.month, from: Date()), birthdayYear: 1985, photoEmoji: "🎸", photoFileName: nil, isFavorite: true),
        WidgetPerson(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, name: "Morgan", birthdayDay: 3, birthdayMonth: (Calendar.current.component(.month, from: Date()) % 12) + 1, birthdayYear: nil, photoEmoji: "🌺", photoFileName: nil, isFavorite: false),
    ]
}
