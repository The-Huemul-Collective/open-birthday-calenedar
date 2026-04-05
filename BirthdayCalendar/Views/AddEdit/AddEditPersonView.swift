import SwiftUI
import SwiftData

enum AddEditMode {
    case add
    case edit(Person)
}

struct AddEditPersonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    let mode: AddEditMode

    @ObservedObject var settings: AppSettings

    // Form state
    @State private var name = ""
    @State private var day: Int = 1
    @State private var month: Int = 1
    @State private var yearText = ""
    @State private var emoji = ""
    @State private var isFavorite = false
    @State private var notificationsEnabled = true

    var theme: any AppTheme { themeManager.current }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var navigationTitle: String {
        isEditing ? L10n.AddEdit.editTitle : L10n.AddEdit.addTitle
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(theme.backgroundPrimary).ignoresSafeArea()

                Form {
                    Section(L10n.AddEdit.sectionPerson) {
                        TextField(L10n.AddEdit.fieldName, text: $name)
                        TextField(L10n.AddEdit.fieldEmoji, text: $emoji)
                            .onChange(of: emoji) {
                                // Limit to one emoji character
                                if emoji.count > 2 {
                                    emoji = String(emoji.prefix(2))
                                }
                            }
                    }

                    Section(L10n.AddEdit.sectionBirthday) {
                        Picker(L10n.AddEdit.fieldMonth, selection: $month) {
                            ForEach(1...12, id: \.self) { m in
                                Text(monthName(m)).tag(m)
                            }
                        }

                        Picker(L10n.AddEdit.fieldDay, selection: $day) {
                            ForEach(validDays, id: \.self) { d in
                                Text("\(d)").tag(d)
                            }
                        }

                        TextField(L10n.AddEdit.fieldYear, text: $yearText)
                            .keyboardType(.numberPad)
                    }

                    Section(L10n.AddEdit.sectionOptions) {
                        Toggle(isOn: $isFavorite) {
                            Label(L10n.AddEdit.optionFavorite, systemImage: "star.fill")
                                .foregroundStyle(theme.favoriteTint)
                        }
                        Toggle(isOn: $notificationsEnabled) {
                            Label(L10n.AddEdit.optionNotif, systemImage: "bell.fill")
                                .foregroundStyle(theme.accent)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.Common.cancel) { dismiss() }
                        .foregroundStyle(theme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Common.save) { save() }
                        .foregroundStyle(theme.accent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadExistingIfEditing() }
        }
    }

    // MARK: - Helpers

    private var validDays: [Int] {
        let maxDay: Int
        switch month {
        case 2:  maxDay = 29
        case 4, 6, 9, 11: maxDay = 30
        default: maxDay = 31
        }
        return Array(1...maxDay)
    }

    private func monthName(_ m: Int) -> String {
        DateFormatter().monthSymbols[m - 1]
    }

    private func loadExistingIfEditing() {
        guard case .edit(let person) = mode else { return }
        name   = person.name
        day    = person.birthdayDay
        month  = person.birthdayMonth
        yearText = person.birthdayYear.map(String.init) ?? ""
        emoji  = person.photoEmoji ?? ""
        isFavorite = person.isFavorite
        notificationsEnabled = person.notificationsEnabled
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let year = Int(yearText)
        let emojiVal = emoji.trimmingCharacters(in: .whitespaces).isEmpty ? nil : emoji

        switch mode {
        case .add:
            let person = Person(
                name: trimmedName,
                birthdayDay: day,
                birthdayMonth: month,
                birthdayYear: year,
                photoEmoji: emojiVal,
                isFavorite: isFavorite,
                notificationsEnabled: notificationsEnabled
            )
            modelContext.insert(person)
            Task {
                await NotificationService.shared.scheduleNotifications(for: person, settings: settings)
            }

        case .edit(let person):
            person.name = trimmedName
            person.birthdayDay = day
            person.birthdayMonth = month
            person.birthdayYear = year
            person.photoEmoji = emojiVal
            person.isFavorite = isFavorite
            person.notificationsEnabled = notificationsEnabled
            Task {
                await NotificationService.shared.scheduleNotifications(for: person, settings: settings)
            }
        }

        dismiss()
    }
}
