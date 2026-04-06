import SwiftUI
import SwiftData

struct EventListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var settings: AppSettings

    @Query(sort: \CountdownEvent.eventDate) private var allEvents: [CountdownEvent]
    @Query(sort: \Person.name) private var allPeople: [Person]
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var eventToEdit: CountdownEvent?

    var theme: any AppTheme { themeManager.current }

    // MARK: - Filtering & grouping

    private var visibleEvents: [CountdownEvent] {
        allEvents.filter { event in
            guard !event.isArchived else { return false }
            if event.isPast {
                switch event.whatsNext {
                case .stayAtZero, .countUp: return true
                case .delete, .archive:     return false
                }
            }
            return true
        }
    }

    private var filteredEvents: [CountdownEvent] {
        guard !searchText.isEmpty else { return visibleEvents }
        return visibleEvents.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var grouped: [(EventSection, [CountdownEvent])] {
        let dict = Dictionary(grouping: filteredEvents, by: \.eventSection)
        return EventSection.allCases.compactMap { section in
            guard let events = dict[section], !events.isEmpty else { return nil }
            let sorted = events.sorted { abs($0.rawDaysUntilEvent) < abs($1.rawDaysUntilEvent) }
            return (section, sorted)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(theme.backgroundPrimary).ignoresSafeArea()

                if visibleEvents.isEmpty && searchText.isEmpty {
                    EmptyStateView(
                        icon: "⏳",
                        title: L10n.EventList.emptyTitle,
                        subtitle: L10n.EventList.emptySubtitle,
                        theme: theme
                    )
                } else if filteredEvents.isEmpty {
                    EmptyStateView(
                        icon: "🔍",
                        title: L10n.EventList.noResultsTitle,
                        subtitle: L10n.EventList.noResultsSubtitle(searchText),
                        theme: theme
                    )
                } else {
                    List {
                        ForEach(grouped, id: \.0) { section, events in
                            Section {
                                ForEach(events) { event in
                                    EventRowView(event: event, resolvedFriends: friends(for: event), theme: theme)
                                        .listRowInsets(EdgeInsets(top: BPSpacing.xs, leading: 0, bottom: BPSpacing.xs, trailing: 0))
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .contentShape(Rectangle())
                                        .onTapGesture { eventToEdit = event }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                delete(event)
                                            } label: {
                                                Label(L10n.Action.delete, systemImage: "trash")
                                            }
                                            Button {
                                                archive(event)
                                            } label: {
                                                Label(L10n.Common.archive, systemImage: "archivebox")
                                            }
                                            .tint(theme.accentSecondary)
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
            .searchable(text: $searchText, prompt: L10n.EventList.searchPlaceholder)
            .navigationTitle(L10n.EventList.title)
            .toolbarColorScheme(theme.navigationColorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(theme.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditEventView(settings: settings, mode: .addEvent)
                .environmentObject(themeManager)
        }
        .sheet(item: $eventToEdit) { event in
            AddEditEventView(settings: settings, mode: .editEvent(event))
                .environmentObject(themeManager)
        }
    }

    // MARK: - Section header

    private func sectionHeader(_ section: EventSection) -> some View {
        Text(section.title)
            .font(BPFont.captionBold())
            .foregroundStyle(theme.sectionHeaderText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, BPSpacing.xl)
            .padding(.top, BPSpacing.md)
            .padding(.bottom, BPSpacing.xs)
            .listRowInsets(EdgeInsets())
            .background(.ultraThinMaterial.opacity(0))
    }

    // MARK: - Actions

    private func delete(_ event: CountdownEvent) {
        Task { await EventNotificationService.shared.removeNotifications(for: event) }
        modelContext.delete(event)
    }

    private func friends(for event: CountdownEvent) -> [Person] {
        allPeople.filter { event.friendIDs.contains($0.id.uuidString) }
    }

    private func archive(_ event: CountdownEvent) {
        event.isArchived = true
        Task { await EventNotificationService.shared.removeNotifications(for: event) }
    }
}
