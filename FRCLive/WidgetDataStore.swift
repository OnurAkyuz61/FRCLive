import Foundation
import WidgetKit

enum WidgetDataStore {
    // Enable this App Group in both app and widget targets:
    // group.onurakyuz.FRCLive
    static let appGroupID = "group.onurakyuz.FRCLive"

    static func writeSnapshot(
        teamNumber: String,
        eventName: String,
        nextMatch: String,
        queueStatus: String,
        updatedAt: String,
        languageCode: String
    ) {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        defaults.set(teamNumber, forKey: "widget_teamNumber")
        defaults.set(eventName, forKey: "widget_eventName")
        defaults.set(nextMatch, forKey: "widget_nextMatch")
        defaults.set(queueStatus, forKey: "widget_queueStatus")
        defaults.set(updatedAt, forKey: "widget_updatedAt")
        defaults.set(languageCode, forKey: "widget_languageCode")
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func syncIdentity(teamNumber: String, languageCode: String) {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        defaults.set(teamNumber, forKey: "widget_teamNumber")
        defaults.set(teamNumber, forKey: "teamNumber")
        defaults.set(languageCode, forKey: "widget_languageCode")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
