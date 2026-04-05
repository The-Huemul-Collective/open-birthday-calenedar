import Foundation

// MARK: - Centralized localization
// All user-facing strings go through this enum.
// Keys map 1:1 to entries in Localizable.strings for each language.

enum L10n {

    // MARK: - Onboarding
    enum Onboarding {
        static var freePitch: String        { loc("onboarding.freePitch") }
        static var freeSubtitle: String     { loc("onboarding.freeSubtitle") }
        static var getStarted: String       { loc("onboarding.getStarted") }
        static var permissionsTitle: String { loc("onboarding.permissionsTitle") }
        static var contactsTitle: String    { loc("onboarding.contacts.title") }
        static var contactsSubtitle: String { loc("onboarding.contacts.subtitle") }
        static var notifTitle: String       { loc("onboarding.notifications.title") }
        static var notifSubtitle: String    { loc("onboarding.notifications.subtitle") }
        static var allowAndContinue: String { loc("onboarding.allowAndContinue") }
        static var skipForNow: String       { loc("onboarding.skipForNow") }
    }

    // MARK: - Birthday List
    enum BirthdayList {
        static var title: String            { loc("birthdayList.title") }
        static var searchPlaceholder: String { loc("birthdayList.searchPlaceholder") }
        static var emptyTitle: String       { loc("birthdayList.empty.title") }
        static var emptySubtitle: String    { loc("birthdayList.empty.subtitle") }
        static var noResultsTitle: String   { loc("birthdayList.noResults.title") }
        static func noResultsSubtitle(_ query: String) -> String {
            String(format: loc("birthdayList.noResults.subtitle"), query)
        }
    }

    // MARK: - Sections
    enum Section {
        static var today: String     { loc("section.today") }
        static var thisWeek: String  { loc("section.thisWeek") }
        static var thisMonth: String { loc("section.thisMonth") }
        static var later: String     { loc("section.later") }
    }

    // MARK: - Swipe Actions
    enum Action {
        static var delete: String    { loc("action.delete") }
        static var mute: String      { loc("action.mute") }
        static var unmute: String    { loc("action.unmute") }
        static var favorite: String  { loc("action.favorite") }
        static var unfavorite: String { loc("action.unfavorite") }
    }

    // MARK: - Add / Edit
    enum AddEdit {
        static var addTitle: String        { loc("addEdit.add.title") }
        static var editTitle: String       { loc("addEdit.edit.title") }
        static var sectionPerson: String   { loc("addEdit.section.person") }
        static var fieldName: String       { loc("addEdit.field.name") }
        static var fieldEmoji: String      { loc("addEdit.field.emoji") }
        static var sectionBirthday: String { loc("addEdit.section.birthday") }
        static var fieldMonth: String      { loc("addEdit.field.month") }
        static var fieldDay: String        { loc("addEdit.field.day") }
        static var fieldYear: String       { loc("addEdit.field.year") }
        static var sectionOptions: String  { loc("addEdit.section.options") }
        static var optionFavorite: String  { loc("addEdit.option.favorite") }
        static var optionNotif: String     { loc("addEdit.option.notifications") }
    }

    // MARK: - Common
    enum Common {
        static var cancel: String { loc("common.cancel") }
        static var save: String   { loc("common.save") }
    }

    // MARK: - Import Contacts
    enum Import {
        static var title: String             { loc("import.title") }
        static func button(_ n: Int) -> String { String(format: loc("import.button"), n) }
        static var importAll: String         { loc("import.importAll") }
        static var loading: String           { loc("import.loading") }
        static var errorTitle: String        { loc("import.error.title") }
        static var errorSubtitle: String     { loc("import.error.subtitle") }
        static var noContactsTitle: String   { loc("import.noContacts.title") }
        static var noContactsSubtitle: String { loc("import.noContacts.subtitle") }
        static var added: String             { loc("import.added") }
    }

    // MARK: - Settings
    enum Settings {
        static var title: String             { loc("settings.title") }
        static var sectionAppearance: String { loc("settings.section.appearance") }
        static var sectionNotif: String      { loc("settings.section.notifications") }
        static var sectionAbout: String      { loc("settings.section.about") }
        static var daily: String             { loc("settings.notification.daily") }
        static var favReminder: String       { loc("settings.notification.favReminder") }
        static func favDays(_ n: Int) -> String { String(format: loc("settings.notification.favDays"), n) }
        static var version: String           { loc("settings.about.version") }
        static var freeForever: String       { loc("settings.about.freeForever") }
        static var freeForeverSub: String    { loc("settings.about.freeForeverSub") }
        static var localData: String         { loc("settings.about.localData") }
        static var localDataSub: String      { loc("settings.about.localDataSub") }
        static var madeWith: String          { loc("settings.about.madeWith") }
    }

    // MARK: - Birthday display
    enum Birthday {
        static func turns(_ n: Int) -> String { String(format: loc("birthday.turns"), n) }
        static var today: String     { loc("birthday.today") }
        static var tomorrow: String  { loc("birthday.tomorrow") }
        static func inDays(_ n: Int) -> String { String(format: loc("birthday.inDays"), n) }
        static var days: String      { loc("birthday.days") }
    }

    // MARK: - Widgets
    enum Widget {
        static var empty: String          { loc("widget.empty") }
        static var emptySubtitle: String  { loc("widget.emptySubtitle") }
        static var favorites: String      { loc("widget.favorites") }
        static var noFavorites: String    { loc("widget.noFavorites") }
        static var noFavoritesSub: String { loc("widget.noFavoritesSub") }
        static var comingUp: String       { loc("widget.comingUp") }
        static var todayBirthday: String  { loc("widget.todayBirthday") }
    }

    // MARK: - Private
    static func loc(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}
