import Foundation

/// Sıra durumu bildirimleri — ön plan ve arka plan aynı anahtarla tekrar göndermez.
enum QueueNotificationCoordinator {
    private static let lastAlertKey = "lastQueueAlertKey"

    static func deliverQueueUpdateIfNeeded(
        eventCode: String,
        snapshot: NexusTeamQueueSnapshot,
        language: AppLanguage
    ) {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }
        guard NexusQueueStatus.shouldNotify(for: snapshot.queuingStatus) else { return }
        guard let nextMatch = snapshot.teamNextMatch, !nextMatch.isEmpty else { return }

        let statusCode = NexusQueueStatus.canonicalCode(snapshot.queuingStatus)
        let alertKey = "\(eventCode)|\(nextMatch)|\(statusCode)"
        guard alertKey != UserDefaults.standard.string(forKey: lastAlertKey) else { return }

        UserDefaults.standard.set(alertKey, forKey: lastAlertKey)
        let statusText = NexusQueueStatus.displayText(snapshot.queuingStatus, language: language)
        AppNotificationManager.shared.sendQueueStatusNotification(
            nextMatch: nextMatch,
            statusText: statusText,
            language: language
        )
    }
}
