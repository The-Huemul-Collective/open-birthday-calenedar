import SwiftUI
import SwiftData
import WidgetKit

struct ImportContactsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var settings: AppSettings

    @Query private var existingPeople: [Person]

    @State private var contacts: [ImportedContact] = []
    @State private var selected: Set<String> = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var theme: any AppTheme { themeManager.current }

    private var alreadyImportedIDs: Set<String> {
        Set(existingPeople.compactMap(\.contactIdentifier))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(theme.backgroundPrimary).ignoresSafeArea()

                if isLoading {
                    ProgressView(L10n.Import.loading)
                        .foregroundStyle(theme.textSecondary)
                } else if let err = errorMessage {
                    EmptyStateView(
                        icon: "🚫",
                        title: L10n.Import.errorTitle,
                        subtitle: err,
                        theme: theme
                    )
                } else if contacts.isEmpty {
                    EmptyStateView(
                        icon: "🔍",
                        title: L10n.Import.noContactsTitle,
                        subtitle: L10n.Import.noContactsSubtitle,
                        theme: theme
                    )
                } else {
                    contactList
                }
            }
            .navigationTitle(L10n.Import.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.Common.cancel) { dismiss() }
                        .foregroundStyle(theme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: BPSpacing.md) {
                        if !contacts.isEmpty {
                            Button(L10n.Import.importAll) {
                                importAll()
                            }
                            .foregroundStyle(theme.textSecondary)
                        }
                        Button(L10n.Import.button(selected.count)) {
                            importSelected()
                        }
                        .foregroundStyle(theme.accent)
                        .disabled(selected.isEmpty)
                    }
                }
            }
            .task { await loadContacts() }
        }
    }

    // MARK: - Contact list

    private var contactList: some View {
        ScrollView {
            LazyVStack(spacing: BPSpacing.sm) {
                ForEach(contacts, id: \.identifier) { contact in
                    let alreadyAdded = alreadyImportedIDs.contains(contact.identifier)
                    HStack {
                        VStack(alignment: .leading, spacing: BPSpacing.xxs) {
                            Text(contact.name)
                                .font(BPFont.titleMedium())
                                .foregroundStyle(alreadyAdded ? theme.textTertiary : theme.textPrimary)
                            Text(shortDate(contact))
                                .font(BPFont.caption())
                                .foregroundStyle(theme.textSecondary)
                        }
                        Spacer()
                        if alreadyAdded {
                            Text(L10n.Import.added)
                                .font(BPFont.captionBold())
                                .foregroundStyle(theme.textTertiary)
                        } else if selected.contains(contact.identifier) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.accent)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(theme.textTertiary)
                        }
                    }
                    .padding(.horizontal, BPSpacing.lg)
                    .padding(.vertical, BPSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: BPRadius.lg)
                            .fill(theme.cardBackground)
                    )
                    .padding(.horizontal, BPSpacing.lg)
                      .contentShape(Rectangle())
                    .onTapGesture {
                        guard !alreadyAdded else { return }
                        if selected.contains(contact.identifier) {
                            selected.remove(contact.identifier)
                        } else {
                            selected.insert(contact.identifier)
                        }
                    }
                }
            }
            .padding(.vertical, BPSpacing.md)
        }
    }

    // MARK: - Actions

    private func loadContacts() async {
        do {
            let granted = try await ContactsService.shared.requestAccess()
            if granted {
                contacts = try await ContactsService.shared.fetchBirthdayContacts()
            } else {
                errorMessage = "Please allow access to Contacts in Settings."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func importAll() {
        let unimported = contacts.filter { !alreadyImportedIDs.contains($0.identifier) }
        for c in unimported {
            let person = Person(
                name: c.name,
                birthdayDay: c.birthdayDay,
                birthdayMonth: c.birthdayMonth,
                birthdayYear: c.birthdayYear,
                contactIdentifier: c.identifier,
                notificationsEnabled: true
            )
            modelContext.insert(person)
            Task {
                await NotificationService.shared.scheduleNotifications(for: person, settings: settings)
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }

    private func importSelected() {
        let toImport = contacts.filter { selected.contains($0.identifier) }
        for c in toImport {
            let person = Person(
                name: c.name,
                birthdayDay: c.birthdayDay,
                birthdayMonth: c.birthdayMonth,
                birthdayYear: c.birthdayYear,
                contactIdentifier: c.identifier,
                notificationsEnabled: true
            )
            modelContext.insert(person)
            Task {
                await NotificationService.shared.scheduleNotifications(for: person, settings: settings)
            }
        }
        // Full sync via PersistenceService so photos are saved too.
        // (RootView.onChange will fire after modelContext commits, but we
        //  also call reloadAllTimelines immediately for responsiveness.)
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }

    private func shortDate(_ c: ImportedContact) -> String {
        let months = ["Jan","Feb","Mar","Apr","May","Jun",
                      "Jul","Aug","Sep","Oct","Nov","Dec"]
        let m = months[c.birthdayMonth - 1]
        if let y = c.birthdayYear { return "\(m) \(c.birthdayDay), \(y)" }
        return "\(m) \(c.birthdayDay)"
    }
}
