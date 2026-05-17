import Foundation
import UserNotifications

/// Nexus tahmin saatlerine göre yerel bildirim planlar — uygulama kapalı olsa da iOS saatinde gösterir.
enum QueueReminderScheduler {
    private static let identifierPrefix = "frclive-scheduled-queue-"
    private static let minimumLeadSeconds: TimeInterval = 90

    static func reschedule(
        eventCode: String,
        schedule: NexusTeamMatchSchedule?,
        language: AppLanguage
    ) async {
        await cancelAll()

        guard UserDefaults.standard.bool(forKey: "notificationsEnabled"),
              let schedule else { return }

        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let milestones = plannedMilestones(for: schedule, nowMilliseconds: nowMs)

        for milestone in milestones {
            await scheduleNotification(
                eventCode: eventCode,
                matchLabel: schedule.matchLabel,
                statusCode: milestone.statusCode,
                fireAtMillis: milestone.fireAtMillis,
                language: language
            )
        }
    }

    static func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private struct PlannedMilestone {
        let statusCode: String
        let fireAtMillis: Int64
    }

    private static func plannedMilestones(
        for schedule: NexusTeamMatchSchedule,
        nowMilliseconds: Int64
    ) -> [PlannedMilestone] {
        let current = NexusQueueStatus.canonicalCode(schedule.queuingStatus)
        var result: [PlannedMilestone] = []

        func appendIfFuture(_ statusCode: String, _ millis: Int64?) {
            guard let millis, millis > nowMilliseconds + Int64(minimumLeadSeconds * 1000) else { return }
            result.append(PlannedMilestone(statusCode: statusCode, fireAtMillis: millis))
        }

        switch current {
        case NexusQueueStatus.onField:
            break
        case NexusQueueStatus.onDeck:
            appendIfFuture(NexusQueueStatus.onField, schedule.estimatedOnFieldTimeMillis)
        case NexusQueueStatus.nowQueuing:
            appendIfFuture(NexusQueueStatus.onDeck, schedule.estimatedOnDeckTimeMillis)
            appendIfFuture(NexusQueueStatus.onField, schedule.estimatedOnFieldTimeMillis)
        default:
            appendIfFuture(NexusQueueStatus.nowQueuing, schedule.estimatedQueueTimeMillis)
            appendIfFuture(NexusQueueStatus.onDeck, schedule.estimatedOnDeckTimeMillis)
            appendIfFuture(NexusQueueStatus.onField, schedule.estimatedOnFieldTimeMillis)
        }

        if result.isEmpty {
            appendIfFuture(NexusQueueStatus.nowQueuing, schedule.estimatedStartTimeMillis)
        }

        return result
    }

    private static func scheduleNotification(
        eventCode: String,
        matchLabel: String,
        statusCode: String,
        fireAtMillis: Int64,
        language: AppLanguage
    ) async {
        let fireDate = Date(timeIntervalSince1970: TimeInterval(fireAtMillis) / 1000.0)
        let interval = fireDate.timeIntervalSinceNow
        guard interval >= minimumLeadSeconds else { return }

        let statusText = NexusQueueStatus.displayText(statusCode, language: language)
        let content = UNMutableNotificationContent()
        content.title = L10n.notificationHeader(type: statusText)
        content.body = matchLabel
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let identifier = "\(identifierPrefix)\(eventCode)-\(matchLabel)-\(statusCode)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
