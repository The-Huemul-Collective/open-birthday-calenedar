import SwiftUI
import SwiftData

struct BirthdayListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var settings: AppSettings
    var openImportOnAppear: Bool = false

    @Query(sort: \Person.name) private var allPeople: [Person]
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var showingImportSheet = false
    @State private var personToEdit: Person?

    @AppStorage("hasShownSwipeHint") private var hasShownSwipeHint = false
    @State private var hintOffset: CGFloat = 0

    var theme: any AppTheme { themeManager.current }

    // MARK: - Filtered & grouped

    private var filteredPeople: [Person] {
        if searchText.isEmpty { return allPeople }
        return allPeople.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var grouped: [(BirthdaySection, [Person])] {
        let dict = Dictionary(grouping: filteredPeople, by: \.birthdaySection)
        return BirthdaySection.allCases.compactMap { section in
            guard let people = dict[section], !people.isEmpty else { return nil }
            return (section, people.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday })
        }
    }

    private var firstPersonID: UUID? { grouped.first?.1.first?.id }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(theme.backgroundPrimary).ignoresSafeArea()

                if allPeople.isEmpty {
                    EmptyStateView(
                        icon: "🎂",
                        title: L10n.BirthdayList.emptyTitle,
                        subtitle: L10n.BirthdayList.emptySubtitle,
                        theme: theme
                    )
                } else if filteredPeople.isEmpty {
                    EmptyStateView(
                        icon: "🔍",
                        title: L10n.BirthdayList.noResultsTitle,
                        subtitle: L10n.BirthdayList.noResultsSubtitle(searchText),
                        theme: theme
                    )
                } else {
                    List {
                        ForEach(grouped, id: \.0) { section, people in
                            Section {
                                ForEach(people) { person in
                                    BirthdayRowView(person: person, theme: theme)
                                        .offset(x: person.id == firstPersonID ? hintOffset : 0)
                                        .listRowInsets(EdgeInsets(top: BPSpacing.xs, leading: 0, bottom: BPSpacing.xs, trailing: 0))
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .contentShape(Rectangle())
                                        .onTapGesture { personToEdit = person }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                delete(person)
                                            } label: {
                                                Label(L10n.Action.delete, systemImage: "trash")
                                            }

                                            Button {
                                                toggleNotifications(for: person)
                                            } label: {
                                                Label(
                                                    person.notificationsEnabled ? L10n.Action.mute : L10n.Action.unmute,
                                                    systemImage: person.notificationsEnabled ? "bell.slash" : "bell"
                                                )
                                            }
                                            .tint(theme.accent)
                                        }
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button {
                                                toggleFavorite(for: person)
                                            } label: {
                                                Label(
                                                    person.isFavorite ? L10n.Action.unfavorite : L10n.Action.favorite,
                                                    systemImage: person.isFavorite ? "star.slash" : "star.fill"
                                                )
                                            }
                                            .tint(theme.favoriteTint)
                                        }
                                }
                            } header: {
                                sectionHeader(section)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .searchable(text: $searchText, prompt: L10n.BirthdayList.searchPlaceholder)
            .onAppear {
                if openImportOnAppear { showingImportSheet = true }
                if !hasShownSwipeHint && !allPeople.isEmpty { playSwipeHint() }
            }
            .navigationTitle(L10n.BirthdayList.title)
            .toolbarColorScheme(theme.navigationColorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingImportSheet = true } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .foregroundStyle(theme.accent)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(theme.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditPersonView(mode: .add, settings: settings).environmentObject(themeManager)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportContactsView(settings: settings).environmentObject(themeManager)
        }
        .sheet(item: $personToEdit) { person in
            AddEditPersonView(mode: .edit(person), settings: settings).environmentObject(themeManager)
        }
    }

    // MARK: - Swipe hint (plays once)

    private func playSwipeHint() {
        let spring = Animation.spring(response: 0.45, dampingFraction: 0.68)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(spring) { hintOffset = -58 }                          // nudge left → delete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(spring) { hintOffset = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(spring) { hintOffset = 48 }                   // nudge right → fav
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        withAnimation(spring) { hintOffset = 0 }
                        hasShownSwipeHint = true
                    }
                }
            }
        }
    }

    // MARK: - Section header

    private func sectionHeader(_ section: BirthdaySection) -> some View {
        Text(section.title)
            .font(BPFont.captionBold())
            .foregroundStyle(theme.sectionHeaderText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, BPSpacing.xl)
            .padding(.top, BPSpacing.md)
            .padding(.bottom, BPSpacing.xs)
            .listRowInsets(EdgeInsets())
            .background(.ultraThinMaterial.opacity(0))  // clear — lets the gradient show through
    }

    // MARK: - Actions

    private func delete(_ person: Person) {
        Task { await NotificationService.shared.removeNotifications(for: person) }
        modelContext.delete(person)
        syncWidgets()
    }

    private func toggleFavorite(for person: Person) {
        person.isFavorite.toggle()
        Task { await NotificationService.shared.scheduleNotifications(for: person, settings: settings) }
        syncWidgets()
    }

    private func toggleNotifications(for person: Person) {
        person.notificationsEnabled.toggle()
        Task { await NotificationService.shared.scheduleNotifications(for: person, settings: settings) }
    }

    private func syncWidgets() {
        PersistenceService.shared.syncWidgetData(from: allPeople)
    }
}
