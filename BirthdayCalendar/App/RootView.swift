import SwiftUI
import SwiftData
import WidgetKit

struct RootView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var settings: AppSettings
    @Query private var allPeople: [Person]

    // Set to true after onboarding so MainTabView immediately opens import sheet
    @State private var openImportAfterOnboarding = false

    var body: some View {
        if !settings.hasCompletedOnboarding {
            OnboardingView(settings: settings, onComplete: {
                openImportAfterOnboarding = true
                settings.hasCompletedOnboarding = true
            })
        } else {
            MainTabView(settings: settings, openImportOnAppear: openImportAfterOnboarding)
                .onAppear {
                    openImportAfterOnboarding = false
                    PersistenceService.shared.syncWidgetData(from: allPeople)
                }
                .onChange(of: allPeople) {
                    PersistenceService.shared.syncWidgetData(from: allPeople)
                }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var settings: AppSettings
    let openImportOnAppear: Bool

    var theme: any AppTheme { themeManager.current }

    var body: some View {
        TabView {
            BirthdayListView(settings: settings, openImportOnAppear: openImportOnAppear)
                .tabItem {
                    Label(L10n.BirthdayList.title, systemImage: "gift.fill")
                }

            SettingsView(settings: settings)
                .tabItem {
                    Label(L10n.Settings.title, systemImage: "gearshape.fill")
                }
        }
        .accentColor(theme.accent)
        .preferredColorScheme(theme.navigationColorScheme)
    }
}
