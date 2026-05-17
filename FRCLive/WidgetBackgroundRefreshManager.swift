import BackgroundTasks
import Foundation
import UIKit

/// Arka planda Nexus'tan canlı veri çekip widget, bildirim ve Live Activity günceller.
enum WidgetBackgroundRefreshManager {
    static let taskIdentifier = "onurakyuz.FRCLive.widgetRefresh"
    static let processingTaskIdentifier = "onurakyuz.FRCLive.queueProcessing"

    private static var refreshInterval: TimeInterval {
        UserDefaults.standard.bool(forKey: "notificationsEnabled") ? 2 * 60 : 5 * 60
    }

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handleAppRefresh(refreshTask)
        }

        BGTaskScheduler.shared.register(forTaskWithIdentifier: processingTaskIdentifier, using: nil) { task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handleProcessing(processingTask)
        }
    }

    /// `urgent: true` — ağ geri gelince veya uygulama arka plana geçince daha erken yenileme dene.
    static func schedule(urgent: Bool = false) {
        guard shouldScheduleBackgroundRefresh() else { return }

        let refreshRequest = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        if urgent {
            refreshRequest.earliestBeginDate = Date(timeIntervalSinceNow: 15)
        } else {
            refreshRequest.earliestBeginDate = Date(timeIntervalSinceNow: refreshInterval)
        }

        do {
            try BGTaskScheduler.shared.submit(refreshRequest)
#if DEBUG
            print("[WidgetBackgroundRefresh] Scheduled app refresh.")
#endif
        } catch {
#if DEBUG
            print("[WidgetBackgroundRefresh] App refresh schedule failed: \(error.localizedDescription)")
#endif
        }

        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }

        let processingRequest = BGProcessingTaskRequest(identifier: processingTaskIdentifier)
        processingRequest.requiresNetworkConnectivity = true
        processingRequest.requiresExternalPower = false
        processingRequest.earliestBeginDate = Date(timeIntervalSinceNow: urgent ? 30 : 3 * 60)

        do {
            try BGTaskScheduler.shared.submit(processingRequest)
#if DEBUG
            print("[WidgetBackgroundRefresh] Scheduled processing refresh.")
#endif
        } catch {
#if DEBUG
            print("[WidgetBackgroundRefresh] Processing schedule failed: \(error.localizedDescription)")
#endif
        }
    }

    static func cancel() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: processingTaskIdentifier)
    }

    @MainActor
    @discardableResult
    static func performWidgetRefresh() async -> Bool {
        let teamNumber = UserDefaults.standard.string(forKey: "teamNumber")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let eventCode = UserDefaults.standard.string(forKey: "selectedEventCode")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let eventName = UserDefaults.standard.string(forKey: "selectedEventName") ?? ""
        let teamNickname = UserDefaults.standard.string(forKey: "teamNickname") ?? ""
        let languageCode = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.tr.rawValue
        let language = AppLanguage(rawValue: languageCode) ?? .tr
        let endDate = UserDefaults.standard.string(forKey: "selectedEventEndDate") ?? ""

        guard !teamNumber.isEmpty, !eventCode.isEmpty, let teamInt = Int(teamNumber) else {
            return false
        }
        guard teamNumber != "99999" else { return false }
        guard !TBAEventCalendar.isStoredEventPastEnd(endYyyyMmDd: endDate) else {
            cancel()
            return false
        }

        do {
            let snapshot = try await NexusAPIClient.shared.fetchQueueSnapshot(
                eventCode: eventCode,
                teamNumber: teamInt
            )
            let statusText = NexusQueueStatus.displayText(snapshot.queuingStatus, language: language)
            let statusCode = NexusQueueStatus.canonicalCode(snapshot.queuingStatus)
            let nextMatch = snapshot.teamNextMatch ?? L10n.text(.noUpcomingMatch, language: language)
            let updatedAt = currentTimeLabel(language: language)

            WidgetDataStore.writeSnapshot(
                teamNumber: teamNumber,
                teamName: teamNickname,
                eventName: eventName.isEmpty ? L10n.text(.eventNotSelected, language: language) : eventName,
                nextMatch: nextMatch,
                currentOnField: snapshot.currentMatchOnField,
                queueStatus: statusText,
                queueStatusCode: statusCode,
                updatedAt: updatedAt,
                languageCode: languageCode
            )

            if UserDefaults.standard.bool(forKey: "liveActivitiesEnabled") {
                await LiveActivityManager.shared.update(
                    teamNumber: teamNumber,
                    eventName: eventName.isEmpty ? L10n.text(.eventNotSelected, language: language) : eventName,
                    nextMatch: nextMatch,
                    status: statusText,
                    statusCode: statusCode,
                    currentOnField: snapshot.currentMatchOnField,
                    estimatedStart: snapshot.estimatedStartTime ?? "-",
                    languageCode: languageCode
                )
            }

            QueueNotificationCoordinator.deliverQueueUpdateIfNeeded(
                eventCode: eventCode,
                snapshot: snapshot,
                language: language
            )
            await QueueReminderScheduler.reschedule(
                eventCode: eventCode,
                schedule: snapshot.teamMatchSchedule,
                language: language
            )

            await AnnouncementStore.shared.refresh(
                eventCode: eventCode,
                teamNumber: teamNumber,
                language: language,
                notify: true
            )

            schedule()
            return true
        } catch {
#if DEBUG
            print("[WidgetBackgroundRefresh] Nexus fetch failed: \(error.localizedDescription)")
#endif
            schedule()
            return false
        }
    }

    private static func shouldScheduleBackgroundRefresh() -> Bool {
        let teamNumber = UserDefaults.standard.string(forKey: "teamNumber")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let eventCode = UserDefaults.standard.string(forKey: "selectedEventCode")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let endDate = UserDefaults.standard.string(forKey: "selectedEventEndDate") ?? ""
        guard !teamNumber.isEmpty, !eventCode.isEmpty, teamNumber != "99999" else { return false }
        return !TBAEventCalendar.isStoredEventPastEnd(endYyyyMmDd: endDate)
    }

    private static func handleAppRefresh(_ task: BGAppRefreshTask) {
        runBackgroundTask(task)
    }

    private static func handleProcessing(_ task: BGProcessingTask) {
        runBackgroundTask(task)
    }

    private static func runBackgroundTask(_ task: BGTask) {
        schedule()

        let work = Task { @MainActor in
            await performWidgetRefresh()
        }

        task.expirationHandler = {
            work.cancel()
        }

        Task {
            let success = await work.value
            task.setTaskCompleted(success: success)
        }
    }

    private static func currentTimeLabel(language: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .en ? "en_US_POSIX" : "tr_TR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}
