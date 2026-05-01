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
    private var currentActivity: Activity<FRCLiveActivityAttributes>?
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

        if currentActivity == nil {
            currentActivity = Activity<FRCLiveActivityAttributes>.activities.first
        }

        if let currentActivity {
            await currentActivity.update(ActivityContent(state: state, staleDate: nil))
        } else {
            do {
                currentActivity = try Activity<FRCLiveActivityAttributes>.request(
                    attributes: FRCLiveActivityAttributes(),
                    content: ActivityContent(state: state, staleDate: nil)
                )
            } catch {
                // Keep non-fatal, but log for easier diagnostics during development.
                print("LiveActivity request failed: \(error.localizedDescription)")
            }
        }
    }

    func end() async {
        guard let currentActivity else { return }
        await currentActivity.end(nil, dismissalPolicy: .immediate)
        self.currentActivity = nil
    }

    func refreshLanguage(_ languageCode: String) async {
        if currentActivity == nil {
            currentActivity = Activity<FRCLiveActivityAttributes>.activities.first
        }
        guard currentActivity != nil else { return }

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
