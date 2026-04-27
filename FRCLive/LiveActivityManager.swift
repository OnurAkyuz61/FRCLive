import ActivityKit
import Foundation

struct FRCLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var teamNumber: String
        var eventName: String
        var nextMatch: String
        var status: String
        var currentOnField: String
        var estimatedStart: String
    }
}

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var currentActivity: Activity<FRCLiveActivityAttributes>?

    private init() {}

    func update(
        teamNumber: String,
        eventName: String,
        nextMatch: String,
        status: String,
        currentOnField: String,
        estimatedStart: String
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = FRCLiveActivityAttributes.ContentState(
            teamNumber: teamNumber,
            eventName: eventName,
            nextMatch: nextMatch,
            status: status,
            currentOnField: currentOnField,
            estimatedStart: estimatedStart
        )

        if let currentActivity {
            await currentActivity.update(ActivityContent(state: state, staleDate: nil))
        } else {
            do {
                currentActivity = try Activity<FRCLiveActivityAttributes>.request(
                    attributes: FRCLiveActivityAttributes(),
                    content: ActivityContent(state: state, staleDate: nil)
                )
            } catch {
                // Ignore request failures silently; UI remains functional without Live Activity.
            }
        }
    }

    func end() async {
        guard let currentActivity else { return }
        await currentActivity.end(nil, dismissalPolicy: .immediate)
        self.currentActivity = nil
    }
}
