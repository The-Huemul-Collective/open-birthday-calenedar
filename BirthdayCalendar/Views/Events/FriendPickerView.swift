import SwiftUI
import SwiftData

struct FriendPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @Query(sort: \Person.name) private var allPeople: [Person]

    @Binding var selectedIDs: Set<UUID>
    @State private var searchText = ""

    var theme: any AppTheme { themeManager.current }

    private var filteredPeople: [Person] {
        guard !searchText.isEmpty else { return allPeople }
        let query = searchText.lowercased()
        return allPeople.filter { person in
            person.name.lowercased().contains(query) ||
            person.name.lowercased().split(separator: " ").contains(where: { $0.hasPrefix(query) })
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(theme.backgroundPrimary).ignoresSafeArea()

                if allPeople.isEmpty {
                    EmptyStateView(
                        icon: "👥",
                        title: "No contacts yet",
                        subtitle: "Add birthdays first to invite friends to events",
                        theme: theme
                    )
                } else {
                    List(filteredPeople) { person in
                        Button {
                            if selectedIDs.contains(person.id) {
                                selectedIDs.remove(person.id)
                            } else {
                                selectedIDs.insert(person.id)
                            }
                        } label: {
                            HStack(spacing: BPSpacing.md) {
                                AvatarView(person: person, size: 40, theme: theme)
                                VStack(alignment: .leading, spacing: BPSpacing.xxs) {
                                    Text(person.name)
                                        .font(BPFont.titleMedium())
                                        .foregroundStyle(theme.textPrimary)
                                    Text(person.formattedBirthday)
                                        .font(BPFont.caption())
                                        .foregroundStyle(theme.textTertiary)
                                }
                                Spacer()
                                if selectedIDs.contains(person.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(theme.accent)
                                        .font(.system(size: 22))
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(theme.textTertiary)
                                        .font(.system(size: 22))
                                }
                            }
                            .padding(.vertical, BPSpacing.xs)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Add Friends")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
            .toolbarColorScheme(theme.navigationColorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(theme.accent)
                }
            }
        }
    }
}

// Convenience on Person so the picker doesn't need extra imports
private extension Person {
    var formattedBirthday: String {
        let months = ["Jan","Feb","Mar","Apr","May","Jun",
                      "Jul","Aug","Sep","Oct","Nov","Dec"]
        return "\(months[birthdayMonth - 1]) \(birthdayDay)"
    }
}
