import Contacts
import Foundation

struct ImportedContact {
    let identifier: String
    let name: String
    let birthdayDay: Int
    let birthdayMonth: Int
    let birthdayYear: Int?
}

final class ContactsService {
    static let shared = ContactsService()
    private let store = CNContactStore()

    func requestAccess() async throws -> Bool {
        try await store.requestAccess(for: .contacts)
    }

    /// Fetches all contacts that have a birthday set.
    func fetchBirthdayContacts() async throws -> [ImportedContact] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
        ]

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)

        var results: [ImportedContact] = []

        try store.enumerateContacts(with: request) { contact, _ in
            guard let bday = contact.birthday,
                  let month = bday.month,
                  let day = bday.day
            else { return }

            let name = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            results.append(ImportedContact(
                identifier: contact.identifier,
                name: name.isEmpty ? "Unknown" : name,
                birthdayDay: day,
                birthdayMonth: month,
                birthdayYear: bday.year
            ))
        }

        return results.sorted { $0.name < $1.name }
    }
}

// CNContact doesn't expose predicateForContactsWithBirthdays publicly on all versions;
// define it as a convenience.
private extension CNContact {
    static func predicateForContactsWithBirthdays() -> NSPredicate {
        // We filter in the enumeration block; return an always-true predicate here.
        NSPredicate(value: true)
    }
}
