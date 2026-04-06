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

    // MARK: - Event sync

    func syncWidgetEvents(from events: [CountdownEvent]) {
        struct Snapshot {
            let id: UUID
            let title: String
            let icon: String
            let eventDate: Date
            let hasTime: Bool
            let formattingUnitRaw: String
            let photoData: Data?
            let textColorHex: String?
            let friendIDs: [String]
            let notificationsEnabled: Bool
        }

        let snapshots = events
            .filter { !$0.isArchived }
            .map { Snapshot(
                id: $0.id,
                title: $0.title,
                icon: $0.icon,
                eventDate: $0.eventDate,
                hasTime: $0.hasTime,
                formattingUnitRaw: $0.formattingUnitRaw,
                photoData: $0.photoData,
                textColorHex: $0.textColorHex,
                friendIDs: $0.friendIDs,
                notificationsEnabled: $0.notificationsEnabled
            ) }

        Task.detached(priority: .utility) {
            let groupID = WidgetDataStore.appGroupID
            var widgetEvents: [WidgetEvent] = []
            for s in snapshots {
                var photoFileName: String? = nil
                if let data = s.photoData,
                   let containerURL = FileManager.default
                       .containerURL(forSecurityApplicationGroupIdentifier: groupID),
                   let original = UIImage(data: data) {
                    let fn = "event_\(s.id.uuidString).jpg"
                    let fileURL = containerURL.appendingPathComponent(fn)

                    // WidgetKit hard-limit: totalArea ≤ 1,235,960 px.
                    // Cap longer edge at 800 px so any aspect ratio stays safely under.
                    let maxEdge: CGFloat = 800
                    let ratio = min(maxEdge / original.size.width,
                                    maxEdge / original.size.height, 1.0)
                    let targetSize = CGSize(width:  (original.size.width  * ratio).rounded(),
                                           height: (original.size.height * ratio).rounded())

                    print("[EventSync] \(fn) original: \(Int(original.size.width))×\(Int(original.size.height)) → target: \(Int(targetSize.width))×\(Int(targetSize.height)) (\(Int(targetSize.width * targetSize.height)) px, limit 1235960)")

                    // format.scale = 1.0: targetSize is interpreted as PIXELS, not points.
                    // Without this UIGraphicsImageRenderer multiplies by screen scale (3×),
                    // turning 533×800 into 1599×2400 which blows the widget limit.
                    let format = UIGraphicsImageRendererFormat()
                    format.scale = 1.0
                    let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
                    let resized = renderer.image { _ in
                        original.draw(in: CGRect(origin: .zero, size: targetSize))
                    }

                    let actualPx = Int(resized.size.width * resized.size.height)
                    print("[EventSync] \(fn) rendered: \(Int(resized.size.width))×\(Int(resized.size.height)) = \(actualPx) px")

                    guard actualPx <= 1_235_960 else {
                        print("[EventSync] ⚠️ \(fn) still too large (\(actualPx) px) — skipping photo")
                        continue
                    }

                    if let jpeg = resized.jpegData(compressionQuality: 0.85) {
                        do {
                            try jpeg.write(to: fileURL, options: .atomic)
                            print("[EventSync] ✅ \(fn) written: \(jpeg.count / 1024) KB")
                            photoFileName = fn
                        } catch {
                            print("[EventSync] ❌ \(fn) write failed: \(error)")
                        }
                    }
                } else if s.photoData != nil {
                    print("[EventSync] ⚠️ \(s.title): photoData present but UIImage init failed or no group container")
                }
                widgetEvents.append(WidgetEvent(
                    id: s.id,
                    title: s.title,
                    icon: s.icon,
                    eventDate: s.eventDate,
                    hasTime: s.hasTime,
                    formattingUnitRaw: s.formattingUnitRaw,
                    photoFileName: photoFileName,
                    textColorHex: s.textColorHex,
                    friendIDs: s.friendIDs,
                    notificationsEnabled: s.notificationsEnabled
                ))
            }
            WidgetDataStore.saveEvents(widgetEvents)
            await MainActor.run { WidgetCenter.shared.reloadAllTimelines() }
        }
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
