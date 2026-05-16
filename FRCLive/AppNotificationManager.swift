import Foundation
import UIKit
import UserNotifications

final class AppNotificationManager {
    static let shared = AppNotificationManager()
    private init() {}

    func sendQueueStatusNotification(teamNumber: String, nextMatch: String, statusText: String) {
        let content = UNMutableNotificationContent()
        content.title = "FRCLive • Takım \(teamNumber)"
        content.body = "\(nextMatch) • \(statusText)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "queue-\(teamNumber)-\(nextMatch)-\(statusText)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    func sendFeedItemNotification(teamNumber: String, item: NexusFeedItem, language: AppLanguage) {
        let content = UNMutableNotificationContent()
        let title: String
        switch item.kind {
        case .announcement:
            title = language == .en
                ? "FRCLive • Event Announcement"
                : "FRCLive • Etkinlik Duyurusu"
        case .partsRequest:
            title = L10n.text(.partsRequestNotificationTitle, language: language)
        }
        content.title = teamNumber.isEmpty ? title : "\(title) • \(teamNumber)"
        content.body = item.message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "feed-\(item.kind.rawValue)-\(item.id)-\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    func sendAnnouncementNotification(teamNumber: String, message: String, language: AppLanguage) {
        let item = NexusFeedItem(
            id: UUID().uuidString,
            kind: .announcement,
            message: message,
            postedTimeMillis: Int64(Date().timeIntervalSince1970 * 1000),
            requestedByTeam: nil,
            pitAddress: nil
        )
        sendFeedItemNotification(teamNumber: teamNumber, item: item, language: language)
    }
}
