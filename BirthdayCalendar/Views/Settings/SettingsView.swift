import SwiftUI
import SwiftData
import WidgetKit

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Query private var allPeople: [Person]

    var theme: any AppTheme { themeManager.current }

    @State private var reminderTime: Date = {
        var comps = DateComponents()
        comps.hour = AppSettings.shared.reminderHour
        comps.minute = AppSettings.shared.reminderMinute
        return Calendar.current.date(from: comps) ?? Date()
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(theme.backgroundPrimary).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: BPSpacing.xl) {

                        // MARK: Appearance
                        settingsSection(title: L10n.Settings.sectionAppearance) {
                            ForEach(AppThemeOption.allCases, id: \.self) { option in
                                settingsRow {
                                    HStack {
                                        Text(option.rawValue)
                                            .font(BPFont.bodyLarge())
                                            .foregroundStyle(theme.textPrimary)
                                        Spacer()
                                        if settings.theme == option {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(theme.accent)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        settings.theme = option
                                        themeManager.apply(option)
                                        WidgetCenter.shared.reloadAllTimelines()
                                    }
                                }
                            }
                        }

                        // MARK: Notifications
                        settingsSection(title: L10n.Settings.sectionNotif) {
                            settingsRow {
                                DatePicker(
                                    L10n.Settings.daily,
                                    selection: $reminderTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .font(BPFont.bodyLarge())
                                .foregroundStyle(theme.textPrimary)
                                .tint(theme.accent)
                                .onChange(of: reminderTime) {
                                    let cal = Calendar.current
                                    settings.reminderHour   = cal.component(.hour, from: reminderTime)
                                    settings.reminderMinute = cal.component(.minute, from: reminderTime)
                                    rescheduleAll()
                                }
                            }

                            Divider()
                                .background(theme.textTertiary.opacity(0.3))
                                .padding(.horizontal, BPSpacing.lg)

                            settingsRow {
                                VStack(alignment: .leading, spacing: BPSpacing.xs) {
                                    HStack {
                                        Text(L10n.Settings.favReminder)
                                            .font(BPFont.bodyLarge())
                                            .foregroundStyle(theme.textPrimary)
                                        Spacer()
                                        Text(L10n.Settings.favDays(settings.favEarlyReminderDays))
                                            .font(BPFont.bodyMedium())
                                            .foregroundStyle(theme.accent)
                                    }
                                    Slider(
                                        value: Binding(
                                            get: { Double(settings.favEarlyReminderDays) },
                                            set: {
                                                settings.favEarlyReminderDays = Int($0)
                                                rescheduleAll()
                                            }
                                        ),
                                        in: 1...30,
                                        step: 1
                                    )
                                    .tint(theme.accent)
                                }
                            }
                        }

                        // MARK: About
                        settingsSection(title: L10n.Settings.sectionAbout) {
                            settingsRow {
                                HStack {
                                    Text(L10n.Settings.version)
                                        .font(BPFont.bodyLarge())
                                        .foregroundStyle(theme.textPrimary)
                                    Spacer()
                                    Text(appVersion)
                                        .font(BPFont.bodyMedium())
                                        .foregroundStyle(theme.textSecondary)
                                }
                            }

                            Divider()
                                .background(theme.textTertiary.opacity(0.3))
                                .padding(.horizontal, BPSpacing.lg)

                            settingsRow {
                                HStack {
                                    VStack(alignment: .leading, spacing: BPSpacing.xxs) {
                                        Text(L10n.Settings.freeForever)
                                            .font(BPFont.bodyLarge())
                                            .foregroundStyle(theme.textPrimary)
                                        Text(L10n.Settings.freeForeverSub)
                                            .font(BPFont.caption())
                                            .foregroundStyle(theme.textSecondary)
                                    }
                                    Spacer()
                                    Text("✅")
                                }
                            }

                            Divider()
                                .background(theme.textTertiary.opacity(0.3))
                                .padding(.horizontal, BPSpacing.lg)

                            settingsRow {
                                HStack {
                                    VStack(alignment: .leading, spacing: BPSpacing.xxs) {
                                        Text(L10n.Settings.localData)
                                            .font(BPFont.bodyLarge())
                                            .foregroundStyle(theme.textPrimary)
                                        Text(L10n.Settings.localDataSub)
                                            .font(BPFont.caption())
                                            .foregroundStyle(theme.textSecondary)
                                    }
                                    Spacer()
                                    Text("🔒")
                                }
                            }
                        }

                        // Made with love
                        Text(L10n.Settings.madeWith)
                            .font(BPFont.caption())
                            .foregroundStyle(theme.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Spacer(minLength: BPSpacing.xxxl)
                    }
                    .padding(.top, BPSpacing.lg)
                }
            }
            .navigationTitle(L10n.Settings.title)
            .toolbarColorScheme(theme.navigationColorScheme, for: .navigationBar)
        }
    }

    // MARK: - Layout helpers

    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: BPSpacing.xs) {
            Text(title.uppercased())
                .font(BPFont.captionBold())
                .foregroundStyle(theme.sectionHeaderText)
                .padding(.horizontal, BPSpacing.xl)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: BPRadius.lg)
                    .fill(theme.cardBackground)
            )
            .padding(.horizontal, BPSpacing.lg)
        }
    }

    private func settingsRow<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(.horizontal, BPSpacing.lg)
            .padding(.vertical, BPSpacing.md)
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func rescheduleAll() {
        let people = allPeople
        let snap = settings
        Task {
            for person in people {
                await NotificationService.shared.scheduleNotifications(for: person, settings: snap)
            }
        }
    }
}
