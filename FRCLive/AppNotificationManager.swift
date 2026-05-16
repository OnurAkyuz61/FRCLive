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

    func sendAnnouncementNotification(teamNumber: String, message: String, language: AppLanguage) {
        let content = UNMutableNotificationContent()
        let title = language == .en
            ? "FRCLive • Event Announcement"
            : "FRCLive • Etkinlik Duyurusu"
        content.title = teamNumber.isEmpty ? title : "\(title) • \(teamNumber)"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "announcement-\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }
}
