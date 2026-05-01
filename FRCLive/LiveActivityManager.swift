import ActivityKit
import Foundation

struct FRCLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var teamNumber: String
        var eventName: String
        var nextMatch: String
        var status: String
        var statusCode: String
        var currentOnField: String
        var estimatedStart: String
        var languageCode: String
    }
}

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private let appGroupID = "group.onurakyuz.FRCLive"

    private init() {}

    func update(
        teamNumber: String,
        eventName: String,
        nextMatch: String,
        status: String,
        statusCode: String,
        currentOnField: String,
        estimatedStart: String,
        languageCode: String
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = FRCLiveActivityAttributes.ContentState(
            teamNumber: teamNumber,
            eventName: eventName,
            nextMatch: nextMatch,
            status: status,
            statusCode: statusCode,
            currentOnField: currentOnField,
            estimatedStart: estimatedStart,
            languageCode: languageCode
        )

        let activeActivities = Activity<FRCLiveActivityAttributes>.activities
        if activeActivities.isEmpty {
            do {
                _ = try Activity<FRCLiveActivityAttributes>.request(
                    attributes: FRCLiveActivityAttributes(),
                    content: ActivityContent(state: state, staleDate: nil)
                )
            } catch {
                // Keep non-fatal, but log for easier diagnostics during development.
                print("LiveActivity request failed: \(error.localizedDescription)")
            }
            return
        }

        for activity in activeActivities {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func end() async {
        let activeActivities = Activity<FRCLiveActivityAttributes>.activities
        guard !activeActivities.isEmpty else { return }
        for activity in activeActivities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    func refreshLanguage(_ languageCode: String) async {
        guard !Activity<FRCLiveActivityAttributes>.activities.isEmpty else { return }

        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        let isEnglish = languageCode == "en"

        let teamNumber = defaults.string(forKey: "widget_teamNumber") ?? defaults.string(forKey: "teamNumber") ?? "----"
        let eventName = defaults.string(forKey: "widget_eventName") ?? (isEnglish ? "Loading..." : "Yükleniyor...")
        let nextMatch = defaults.string(forKey: "widget_nextMatch") ?? "-"
        let status = defaults.string(forKey: "widget_queueStatus") ?? (isEnglish ? "Loading live data..." : "Canlı veri yükleniyor...")
        let statusCode = defaults.string(forKey: "widget_queueStatusCode") ?? "Unknown"
        let currentOnField = defaults.string(forKey: "widget_currentOnField") ?? "-"

        await update(
            teamNumber: teamNumber,
            eventName: eventName,
            nextMatch: nextMatch,
            status: status,
            statusCode: statusCode,
            currentOnField: currentOnField,
            estimatedStart: "-",
            languageCode: languageCode
        )
    }
}
