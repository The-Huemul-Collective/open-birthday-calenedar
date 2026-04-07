import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Mode

enum AddEditEventMode {
    case addEvent
    case editEvent(CountdownEvent)
}

// MARK: - View

struct AddEditEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var settings: AppSettings
    @Query(sort: \Person.name) private var allPeople: [Person]

    let mode: AddEditEventMode

    // Form state
    @State private var title = ""
    @State private var icon = "🎉"
    @State private var eventDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var hasTime = false
    @State private var repeatRule: EventRepeatRule = .never
    @State private var whatsNext: EventWhatsNext = .stayAtZero
    @State private var notificationsEnabled = true
    @State private var earlyReminderDays = 0
    @State private var startDate = Date()
    @State private var excludeWeekends = false
    @State private var formattingUnit: EventFormattingUnit = .days

    // Photo & color
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoUIImage: UIImage?
    @State private var useCustomTextColor = false
    @State private var customTextColor: Color = .white

    @State private var selectedFriendIDs: Set<UUID> = []

    // Sheets
    @State private var showingModifiersSheet = false
    @State private var showingFriendPicker = false
    @State private var showingDeleteAlert = false

    var theme: any AppTheme { themeManager.current }

    private var isEditing: Bool {
        if case .editEvent = mode { return true }
        return false
    }

    // MARK: - Computed countdown for preview

    private var previewRawDays: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: eventDate)
        return cal.dateComponents([.day], from: today, to: target).day ?? 0
    }

    private var previewDays: Int {
        let raw = previewRawDays
        guard excludeWeekends, raw > 0 else { return raw }
        let cal = Calendar.current
        var weekdays = 0
        var current = cal.startOfDay(for: Date())
        for _ in 0..<raw {
            current = cal.date(byAdding: .day, value: 1, to: current)!
            let wd = cal.component(.weekday, from: current)
            if wd != 1 && wd != 7 { weekdays += 1 }
        }
        return weekdays
    }

    private var previewIsPast: Bool { previewRawDays < 0 }
    private var previewIsToday: Bool { previewRawDays == 0 }

    private var previewCountdownValue: Int {
        let days = abs(previewDays)
        switch formattingUnit {
        case .days:   return days
        case .weeks:  return days / 7
        case .months:
            let cal = Calendar.current
            let (from, to) = previewIsPast ? (eventDate, Date()) : (Date(), eventDate)
            return abs(cal.dateComponents([.month], from: from, to: to).month ?? 0)
        case .years:
            let cal = Calendar.current
            let (from, to) = previewIsPast ? (eventDate, Date()) : (Date(), eventDate)
            return abs(cal.dateComponents([.year], from: from, to: to).year ?? 0)
        }
    }

    private var previewCountdownLabel: String {
        let v = previewCountdownValue
        switch formattingUnit {
        case .days:   return v == 1 ? "day" : "days"
        case .weeks:  return v == 1 ? "week" : "weeks"
        case .months: return v == 1 ? "month" : "months"
        case .years:  return v == 1 ? "year" : "years"
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(theme.backgroundPrimary).ignoresSafeArea()

                Form {
                    // Widget preview
                    previewSection

                    // Title & icon
                    Section {
                        HStack(spacing: BPSpacing.md) {
                            TextField("", text: $icon)
                                .multilineTextAlignment(.center)
                                .frame(width: 44)
                                .onChange(of: icon) { _, v in
                                    if v.count > 1 { icon = String(v.prefix(1)) }
                                }
                            Divider()
                            TextField(L10n.AddEvent.fieldTitle, text: $title)
                        }
                    }

                    // Date & time
                    Section {
                        DatePicker(
                            L10n.AddEvent.fieldDate,
                            selection: $eventDate,
                            displayedComponents: hasTime ? [.date, .hourAndMinute] : .date
                        )
                        Toggle(isOn: $hasTime) {
                            Label(L10n.AddEvent.fieldTime, systemImage: "clock")
                                .foregroundStyle(theme.accent)
                        }
                    }

                    // Repeat & what's next
                    Section {
                        Picker(selection: $repeatRule) {
                            ForEach(EventRepeatRule.allCases, id: \.self) { rule in
                                Text(rule.rawValue).tag(rule)
                            }
                        } label: {
                            Label(L10n.AddEvent.fieldRepeat, systemImage: "repeat")
                                .foregroundStyle(theme.textPrimary)
                        }

                        Picker(selection: $whatsNext) {
                            ForEach(EventWhatsNext.allCases, id: \.self) { w in
                                Text(w.rawValue).tag(w)
                            }
                        } label: {
                            Label(L10n.AddEvent.fieldWhatsNext, systemImage: "infinity")
                                .foregroundStyle(theme.textPrimary)
                        }
                    }

                    // Appearance
                    Section {
                        photoPicker
                        if photoData != nil {
                            Button(L10n.AddEvent.removePhoto, role: .destructive) {
                                photoData = nil
                                photoUIImage = nil
                                photosPickerItem = nil
                            }
                        }
                        Toggle(isOn: $useCustomTextColor) {
                            Label(L10n.AddEvent.fieldTextColor, systemImage: "textformat")
                                .foregroundStyle(theme.textPrimary)
                        }
                        if useCustomTextColor {
                            ColorPicker(L10n.AddEvent.textColor, selection: $customTextColor, supportsOpacity: false)
                        }
                    }

                    // Notifications
                    Section {
                        Toggle(isOn: $notificationsEnabled) {
                            Label(L10n.AddEvent.fieldNotifications, systemImage: "bell.fill")
                                .foregroundStyle(theme.accent)
                        }
                        if notificationsEnabled {
                            Picker(selection: $earlyReminderDays) {
                                Text(L10n.AddEvent.noReminder).tag(0)
                                Text(L10n.AddEvent.oneDayBefore).tag(1)
                                ForEach([3, 7, 14, 30], id: \.self) { d in
                                    Text(L10n.AddEvent.daysBefore(d)).tag(d)
                                }
                            } label: {
                                Label(L10n.AddEvent.fieldEarlyReminder, systemImage: "bell.badge")
                                    .foregroundStyle(theme.textPrimary)
                            }
                        }
                    }

                    // Advanced
                    Section {
                        Button {
                            showingModifiersSheet = true
                        } label: {
                            HStack {
                                Label(L10n.AddEvent.modifiers, systemImage: "slider.horizontal.3")
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                if excludeWeekends {
                                    Text(L10n.AddEvent.exclWeekends)
                                        .font(BPFont.caption())
                                        .foregroundStyle(theme.textSecondary)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(theme.textTertiary)
                            }
                        }

                        Picker(selection: $formattingUnit) {
                            ForEach(EventFormattingUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        } label: {
                            Label(L10n.AddEvent.fieldFormatting, systemImage: "number")
                                .foregroundStyle(theme.textPrimary)
                        }
                    }

                    // Friends
                    Section {
                        Button {
                            showingFriendPicker = true
                        } label: {
                            HStack {
                                Label(L10n.AddEvent.fieldFriends, systemImage: "person.2.fill")
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                if selectedFriendIDs.isEmpty {
                                    Text(L10n.Common.none)
                                        .foregroundStyle(theme.textTertiary)
                                } else {
                                    FriendAvatarStack(
                                        friends: previewFriends,
                                        size: 26,
                                        theme: theme,
                                        maxVisible: 4
                                    )
                                }
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(theme.textTertiary)
                            }
                        }
                    }

                    // Start date
                    Section {
                        DatePicker(
                            L10n.AddEvent.fieldStartDate,
                            selection: $startDate,
                            displayedComponents: .date
                        )
                    }

                    // Edit-only actions
                    if isEditing {
                        Section {
                            Button(L10n.AddEvent.duplicate) { duplicate() }
                                .foregroundStyle(theme.accent)
                            Button(L10n.AddEvent.archive) { archiveAndDismiss() }
                                .foregroundStyle(theme.accent)
                        }
                        Section {
                            Button(L10n.AddEvent.delete, role: .destructive) {
                                showingDeleteAlert = true
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? L10n.AddEvent.editTitle : L10n.AddEvent.addTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.Common.cancel) { dismiss() }
                        .foregroundStyle(theme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Common.save) { save() }
                        .foregroundStyle(theme.accent)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadIfEditing() }
            .onChange(of: photosPickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                        photoUIImage = UIImage(data: data)
                    }
                }
            }
            .sheet(isPresented: $showingModifiersSheet) {
                modifiersSheet
            }
            .sheet(isPresented: $showingFriendPicker) {
                FriendPickerView(selectedIDs: $selectedFriendIDs)
                    .environmentObject(themeManager)
            }
            .alert(L10n.AddEvent.deleteAlert, isPresented: $showingDeleteAlert) {
                Button(L10n.AddEvent.delete, role: .destructive) { deleteAndDismiss() }
                Button(L10n.Common.cancel, role: .cancel) {}
            } message: {
                Text(L10n.AddEvent.deleteMessage)
            }
        }
    }

    // MARK: - Widget preview section

    private var previewFriends: [Person] {
        allPeople.filter { selectedFriendIDs.contains($0.id) }
    }

    private var previewSection: some View {
        Section {
            HStack {
                Spacer()
                EventWidgetPreview(
                    icon: icon,
                    title: title,
                    eventDate: eventDate,
                    hasTime: hasTime,
                    countdownValue: previewCountdownValue,
                    countdownLabel: previewCountdownLabel,
                    isPast: previewIsPast,
                    isToday: previewIsToday,
                    photoData: photoData,
                    textColorHex: useCustomTextColor ? customTextColor.hexString : nil,
                    friends: previewFriends,
                    theme: theme
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: previewCountdownValue)
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: icon)
                Spacer()
            }
            .padding(.vertical, BPSpacing.sm)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    // MARK: - Photo picker

    private var photoPicker: some View {
        PhotosPicker(selection: $photosPickerItem, matching: .images) {
            HStack {
                Label(L10n.AddEvent.fieldPhoto, systemImage: "photo")
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                if let img = photoUIImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: BPRadius.sm))
                } else {
                    Text(L10n.Common.none)
                        .foregroundStyle(theme.textTertiary)
                }
            }
        }
    }

    // MARK: - Modifiers sheet

    private var modifiersSheet: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(theme.backgroundPrimary).ignoresSafeArea()
                Form {
                    Section(L10n.AddEvent.modifiers) {
                        Toggle(isOn: $excludeWeekends) {
                            Label(L10n.AddEvent.excludeWeekends, systemImage: "calendar.badge.minus")
                                .foregroundStyle(theme.textPrimary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(L10n.AddEvent.modifiersTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Common.done) { showingModifiersSheet = false }
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Load / save / actions

    private func loadIfEditing() {
        guard case .editEvent(let event) = mode else { return }
        title               = event.title
        icon                = event.icon
        eventDate           = event.eventDate
        hasTime             = event.hasTime
        repeatRule          = event.repeatRule
        whatsNext           = event.whatsNext
        notificationsEnabled = event.notificationsEnabled
        earlyReminderDays   = event.earlyReminderDays
        startDate           = event.startDate
        excludeWeekends     = event.excludeWeekends
        formattingUnit      = event.formattingUnit
        photoData           = event.photoData
        if let data = event.photoData { photoUIImage = UIImage(data: data) }
        if let hex = event.textColorHex, let color = Color(hex: hex) {
            useCustomTextColor = true
            customTextColor = color
        }
        selectedFriendIDs = Set(event.friendIDs.compactMap { UUID(uuidString: $0) })
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        switch mode {
        case .addEvent:
            let event = CountdownEvent(
                title: trimmed,
                icon: icon.isEmpty ? "🎉" : icon,
                eventDate: eventDate,
                hasTime: hasTime,
                repeatRule: repeatRule,
                whatsNext: whatsNext,
                photoData: photoData,
                notificationsEnabled: notificationsEnabled,
                earlyReminderDays: earlyReminderDays,
                startDate: startDate,
                excludeWeekends: excludeWeekends,
                formattingUnit: formattingUnit,
                textColorHex: useCustomTextColor ? customTextColor.hexString : nil,
                friendIDsCSV: selectedFriendIDs.map { $0.uuidString }.joined(separator: ",")
            )
            modelContext.insert(event)
            Task { await EventNotificationService.shared.scheduleNotifications(for: event, settings: settings) }

        case .editEvent(let event):
            event.title               = trimmed
            event.icon                = icon.isEmpty ? "🎉" : icon
            event.eventDate           = eventDate
            event.hasTime             = hasTime
            event.repeatRule          = repeatRule
            event.whatsNext           = whatsNext
            event.photoData           = photoData
            event.notificationsEnabled = notificationsEnabled
            event.earlyReminderDays   = earlyReminderDays
            event.startDate           = startDate
            event.excludeWeekends     = excludeWeekends
            event.formattingUnit      = formattingUnit
            event.textColorHex        = useCustomTextColor ? customTextColor.hexString : nil
            event.friendIDs           = selectedFriendIDs.map { $0.uuidString }
            Task { await EventNotificationService.shared.scheduleNotifications(for: event, settings: settings) }
        }

        dismiss()
    }

    private func duplicate() {
        guard case .editEvent(let event) = mode else { return }
        let copy = CountdownEvent(
            title: "\(event.title) (copy)",
            icon: event.icon,
            eventDate: event.eventDate,
            hasTime: event.hasTime,
            repeatRule: event.repeatRule,
            whatsNext: event.whatsNext,
            photoData: event.photoData,
            notificationsEnabled: event.notificationsEnabled,
            earlyReminderDays: event.earlyReminderDays,
            startDate: event.startDate,
            excludeWeekends: event.excludeWeekends,
            formattingUnit: event.formattingUnit,
            textColorHex: event.textColorHex,
            friendIDsCSV: event.friendIDsCSV
        )
        modelContext.insert(copy)
        Task { await EventNotificationService.shared.scheduleNotifications(for: copy, settings: settings) }
        dismiss()
    }

    private func archiveAndDismiss() {
        guard case .editEvent(let event) = mode else { return }
        event.isArchived = true
        Task { await EventNotificationService.shared.removeNotifications(for: event) }
        dismiss()
    }

    private func deleteAndDismiss() {
        guard case .editEvent(let event) = mode else { return }
        Task { await EventNotificationService.shared.removeNotifications(for: event) }
        modelContext.delete(event)
        dismiss()
    }
}
