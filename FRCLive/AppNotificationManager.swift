import Foundation
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
}
