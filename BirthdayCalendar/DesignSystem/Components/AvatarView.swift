import SwiftUI
import Contacts

/// Circular avatar showing contact photo, emoji, or initials fallback.
struct AvatarView: View {
    let person: Person
    let size: CGFloat
    let theme: any AppTheme

    @State private var contactImage: UIImage?

    init(person: Person, size: CGFloat = 48, theme: any AppTheme) {
        self.person = person
        self.size = size
        self.theme = theme
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.avatarRing)
                .frame(width: size + 3, height: size + 3)

            Group {
                if let img = contactImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else if let emoji = person.photoEmoji {
                    Text(emoji)
                        .font(.system(size: size * 0.48))
                        .frame(width: size, height: size)
                        .background(initialsBackground)
                } else {
                    Text(initials)
                        .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                        .frame(width: size, height: size)
                        .background(initialsBackground)
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        }
        .task(id: person.contactIdentifier) {
            await loadContactPhoto()
        }
    }

    // MARK: - Helpers

    private var initials: String {
        let parts = person.name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map(String.init) }
        return letters.joined().uppercased()
    }

    private var initialsBackground: some View {
        Circle().fill(theme.backgroundSecondary)
    }

    private func loadContactPhoto() async {
        guard let identifier = person.contactIdentifier else { return }
        let store = CNContactStore()
        let keys = [CNContactImageDataKey as CNKeyDescriptor]
        guard let contact = try? store.unifiedContact(withIdentifier: identifier, keysToFetch: keys),
              let data = contact.imageData,
              let img = UIImage(data: data)
        else { return }
        await MainActor.run { contactImage = img }
    }
}
