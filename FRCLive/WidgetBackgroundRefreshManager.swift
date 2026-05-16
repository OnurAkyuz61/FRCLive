import BackgroundTasks
import Foundation
import UIKit

/// Arka planda Nexus'tan canlı veri çekip widget (ve isteğe bağlı Live Activity) günceller.
enum WidgetBackgroundRefreshManager {
    static let taskIdentifier = "onurakyuz.FRCLive.widgetRefresh"
    private static let refreshInterval: TimeInterval = 5 * 60

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handleAppRefresh(refreshTask)
        }
    }

    static func schedule() {
        guard shouldScheduleBackgroundRefresh() else { return }

        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: refreshInterval)

        do {
            try BGTaskScheduler.shared.submit(request)
#if DEBUG
            print("[WidgetBackgroundRefresh] Scheduled next refresh (~\(Int(refreshInterval / 60)) min).")
#endif
        } catch {
#if DEBUG
            print("[WidgetBackgroundRefresh] Schedule failed: \(error.localizedDescription)")
#endif
        }
    }

    static func cancel() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
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
            let statusText = localizedStatus(snapshot.queuingStatus, language: language)
            let nextMatch = snapshot.teamNextMatch ?? L10n.text(.noUpcomingMatch, language: language)
            let updatedAt = currentTimeLabel(language: language)

            WidgetDataStore.writeSnapshot(
                teamNumber: teamNumber,
                teamName: teamNickname,
                eventName: eventName.isEmpty ? L10n.text(.eventNotSelected, language: language) : eventName,
                nextMatch: nextMatch,
                currentOnField: snapshot.currentMatchOnField,
                queueStatus: statusText,
                queueStatusCode: snapshot.queuingStatus.rawValue,
                updatedAt: updatedAt,
                languageCode: languageCode
            )

            if UserDefaults.standard.bool(forKey: "liveActivitiesEnabled") {
                await LiveActivityManager.shared.update(
                    teamNumber: teamNumber,
                    eventName: eventName.isEmpty ? L10n.text(.eventNotSelected, language: language) : eventName,
                    nextMatch: nextMatch,
                    status: statusText,
                    statusCode: snapshot.queuingStatus.rawValue,
                    currentOnField: snapshot.currentMatchOnField,
                    estimatedStart: snapshot.estimatedStartTime ?? "-",
                    languageCode: languageCode
                )
            }

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

    private static func localizedStatus(_ status: NexusQueuingStatus, language: AppLanguage) -> String {
        switch status {
        case .notCalled:
            return L10n.text(.queueStatusNotCalled, language: language)
        case .calledToQueue:
            return L10n.text(.queueStatusCalled, language: language)
        case .onField:
            return L10n.text(.queueStatusOnField, language: language)
        case .unknown:
            return L10n.text(.queueStatusUnknown, language: language)
        }
    }

    private static func currentTimeLabel(language: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .en ? "en_US_POSIX" : "tr_TR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}
