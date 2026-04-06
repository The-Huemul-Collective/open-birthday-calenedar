import SwiftUI
import SwiftData
import WidgetKit

@main
struct BirthdayCalendarApp: App {
    @StateObject private var themeManager: ThemeManager
    @StateObject private var settings = AppSettings.shared

    private let containerResult: Result<ModelContainer, Error>
    private let diagnostics: String

    init() {
        let s = AppSettings.shared
        _themeManager = StateObject(wrappedValue: ThemeManager(option: s.theme))

        var log = ""

        // ── 1. App Group container ──────────────────────────────────────────
        let fm = FileManager.default
        let groupID = "group.com.open.birthdaycalendar"
        if let groupURL = fm.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            log += "groupURL: \(groupURL.path)\n"
            let files = (try? fm.contentsOfDirectory(atPath: groupURL.path)) ?? []
            log += "files: \(files)\n"
        } else {
            log += "groupURL: NIL — App Group not accessible\n"
        }

        // ── 2. Try Person store alone ───────────────────────────────────────
        let personConfig = ModelConfiguration(
            schema: Schema([Person.self]),
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(groupID)
        )
        do {
            _ = try ModelContainer(for: Schema([Person.self]), configurations: personConfig)
            log += "Person-only container: OK\n"
        } catch {
            log += "Person-only container FAILED: \(error)\n"
            let ns = error as NSError
            log += "  domain=\(ns.domain) code=\(ns.code)\n"
            log += "  userInfo=\(ns.userInfo)\n"
            if let u = ns.userInfo[NSUnderlyingErrorKey] as? NSError {
                log += "  underlying=\(u)\n"
            }
        }

        // ── 3. Try CountdownEvent store alone ──────────────────────────────
        let eventConfig = ModelConfiguration(
            "Events",
            schema: Schema([CountdownEvent.self]),
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(groupID)
        )
        do {
            _ = try ModelContainer(for: Schema([CountdownEvent.self]), configurations: eventConfig)
            log += "Events-only container: OK\n"
        } catch {
            log += "Events-only container FAILED: \(error)\n"
            let ns = error as NSError
            log += "  domain=\(ns.domain) code=\(ns.code)\n"
            log += "  userInfo=\(ns.userInfo)\n"
            if let u = ns.userInfo[NSUnderlyingErrorKey] as? NSError {
                log += "  underlying=\(u)\n"
            }
        }

        // ── 4. Try combined container ──────────────────────────────────────
        let personConfig2 = ModelConfiguration(
            schema: Schema([Person.self]),
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(groupID)
        )
        let eventConfig2 = ModelConfiguration(
            "Events",
            schema: Schema([CountdownEvent.self]),
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(groupID)
        )
        do {
            let container = try ModelContainer(
                for: Schema([Person.self, CountdownEvent.self]),
                configurations: personConfig2, eventConfig2
            )
            containerResult = .success(container)
            diagnostics = log + "Combined container: OK\n"
        } catch {
            containerResult = .failure(error)
            log += "Combined container FAILED: \(error)\n"
            let ns = error as NSError
            log += "  domain=\(ns.domain) code=\(ns.code)\n"
            log += "  userInfo=\(ns.userInfo)\n"
            if let u = ns.userInfo[NSUnderlyingErrorKey] as? NSError {
                log += "  underlying=\(u)\n"
            }
            diagnostics = log
        }
    }

    var body: some Scene {
        WindowGroup {
            switch containerResult {
            case .success:
                RootView(settings: settings)
                    .environmentObject(themeManager)
                    .environmentObject(settings)
                    .environment(\.themeManager, themeManager)
                    .onAppear { WidgetCenter.shared.reloadAllTimelines() }
            case .failure(let error):
                DatabaseErrorView(error: error, diagnostics: diagnostics)
            }
        }
        .modelContainer(safeContainer)
    }

    private var safeContainer: ModelContainer {
        switch containerResult {
        case .success(let c): return c
        case .failure:
            return try! ModelContainer(
                for: Schema([Person.self, CountdownEvent.self]),
                configurations:
                    ModelConfiguration(schema: Schema([Person.self]), isStoredInMemoryOnly: true),
                    ModelConfiguration("Events", schema: Schema([CountdownEvent.self]), isStoredInMemoryOnly: true)
            )
        }
    }
}
