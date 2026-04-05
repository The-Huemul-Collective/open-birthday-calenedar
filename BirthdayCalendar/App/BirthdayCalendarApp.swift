import SwiftUI
import SwiftData
import WidgetKit

@main
struct BirthdayCalendarApp: App {
    @StateObject private var themeManager: ThemeManager
    @StateObject private var settings = AppSettings.shared

    init() {
        let s = AppSettings.shared
        _themeManager = StateObject(
            wrappedValue: ThemeManager(option: s.theme)
        )
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Person.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.open.birthdaycalendar")
        )
        return try! ModelContainer(for: schema, configurations: config)
    }()

    var body: some Scene {
        WindowGroup {
            RootView(settings: settings)
                .environmentObject(themeManager)
                .environmentObject(settings)
                .environment(\.themeManager, themeManager)
                .onAppear {
                    // Reload widgets so they pick up the current theme immediately
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
