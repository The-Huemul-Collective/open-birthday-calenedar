import SwiftData
import Foundation
import Contacts
import UIKit
import WidgetKit

/// Handles syncing SwiftData → App Group JSON + photos so widgets stay up to date.
final class PersistenceService {
    static let shared = PersistenceService()
    private let store = CNContactStore()

    // Capture value types off the SwiftData objects immediately,
    // then do the Contacts + file work on a background thread.
    func syncWidgetData(from people: [Person]) {
        struct Snapshot {
            let id: UUID
            let name: String
            let birthdayDay: Int
            let birthdayMonth: Int
            let birthdayYear: Int?
            let photoEmoji: String?
            let contactIdentifier: String?
            let isFavorite: Bool
        }

        let snapshots = people.map {
            Snapshot(
                id: $0.id,
                name: $0.name,
                birthdayDay: $0.birthdayDay,
                birthdayMonth: $0.birthdayMonth,
                birthdayYear: $0.birthdayYear,
                photoEmoji: $0.photoEmoji,
                contactIdentifier: $0.contactIdentifier,
                isFavorite: $0.isFavorite
            )
        }

        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            var widgetPeople: [WidgetPerson] = []
            for s in snapshots {
                let fileName = self.savePhoto(identifier: s.contactIdentifier, personID: s.id)
                widgetPeople.append(WidgetPerson(
                    id: s.id,
                    name: s.name,
                    birthdayDay: s.birthdayDay,
                    birthdayMonth: s.birthdayMonth,
                    birthdayYear: s.birthdayYear,
                    photoEmoji: s.photoEmoji,
                    photoFileName: fileName,
                    isFavorite: s.isFavorite
                ))
            }
            WidgetDataStore.save(widgetPeople)
            // Reload after save so widgets always reflect the latest data
            await MainActor.run {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    // MARK: - Photo persistence

    /// Saves the contact photo as a 60×60 JPEG in the App Group container.
    /// Tries full-res imageData first, falls back to thumbnailImageData.
    private func savePhoto(identifier: String?, personID: UUID) -> String? {
        guard let identifier,
              let containerURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: WidgetDataStore.appGroupID)
        else { return nil }

        let fileName = "photo_\(personID.uuidString).jpg"
        let fileURL = containerURL.appendingPathComponent(fileName)

        // Already saved — skip Contacts fetch
        if FileManager.default.fileExists(atPath: fileURL.path) { return fileName }

        let keys: [CNKeyDescriptor] = [
            CNContactImageDataKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactImageDataAvailableKey as CNKeyDescriptor,
        ]

        guard let contact = try? store.unifiedContact(withIdentifier: identifier, keysToFetch: keys),
              contact.imageDataAvailable
        else { return nil }

        // Prefer full-res, fall back to thumbnail
        let rawData = contact.imageData ?? contact.thumbnailImageData

        guard let rawData,
              let image = UIImage(data: rawData)
        else { return nil }

        let targetSize = CGSize(width: 80, height: 80)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let jpeg = resized.jpegData(compressionQuality: 0.85) else { return nil }
        try? jpeg.write(to: fileURL, options: .atomic)
        return fileName
    }

    /// Force-refreshes a single person's photo (call after the user changes their contact photo).
    func invalidatePhoto(for personID: UUID) {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: WidgetDataStore.appGroupID)
        else { return }
        let fileURL = containerURL.appendingPathComponent("photo_\(personID.uuidString).jpg")
        try? FileManager.default.removeItem(at: fileURL)
    }
}
