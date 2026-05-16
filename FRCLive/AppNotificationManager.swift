import Foundation
import UIKit
import UserNotifications

final class AppNotificationManager {
    static let shared = AppNotificationManager()
    private init() {}

    func sendQueueStatusNotification(
        nextMatch: String,
        statusText: String,
        language: AppLanguage
    ) {
        let content = UNMutableNotificationContent()
        content.title = L10n.notificationHeader(type: statusText)
        content.body = nextMatch
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "queue-\(nextMatch)-\(statusText)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    func sendFeedItemNotification(item: NexusFeedItem, language: AppLanguage) {
        let content = UNMutableNotificationContent()
        content.title = item.notificationTitle(language: language)
        content.body = item.message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "feed-\(item.kind.rawValue)-\(item.id)-\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    func sendAnnouncementNotification(message: String, language: AppLanguage) {
        let item = NexusFeedItem(
            id: UUID().uuidString,
            kind: .announcement,
            message: message,
            postedTimeMillis: Int64(Date().timeIntervalSince1970 * 1000),
            requestedByTeam: nil,
            pitAddress: nil,
            announcementSubtype: NexusFeedItem.classifyAnnouncement(message: message)
        )
        sendFeedItemNotification(item: item, language: language)
    }
}
