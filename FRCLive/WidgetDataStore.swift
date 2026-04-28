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

    static func syncAppState(teamNumber: String, selectedEventCode: String, languageCode: String) {
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        let isEnglish = languageCode == "en"

        let normalizedTeam = teamNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEventCode = selectedEventCode.trimmingCharacters(in: .whitespacesAndNewlines)

        let eventName: String
        let nextMatch: String
        let queueStatus: String

        if normalizedTeam.isEmpty {
            eventName = isEnglish ? "Please enter a team number" : "Lutfen bir takim numarasi girin"
            nextMatch = "-"
            queueStatus = isEnglish ? "Waiting for team selection" : "Takim secimi bekleniyor"
        } else if normalizedEventCode.isEmpty {
            eventName = isEnglish ? "Please select an event" : "Lutfen bir etkinlik secin"
            nextMatch = "-"
            queueStatus = isEnglish ? "Waiting for event selection" : "Etkinlik secimi bekleniyor"
        } else {
            eventName = defaults.string(forKey: "widget_eventName") ?? (isEnglish ? "Loading..." : "Yukleniyor...")
            nextMatch = defaults.string(forKey: "widget_nextMatch") ?? "-"
            queueStatus = defaults.string(forKey: "widget_queueStatus") ?? (isEnglish ? "Loading live data..." : "Canli veri yukleniyor...")
        }

        defaults.set(teamNumber, forKey: "widget_teamNumber")
        defaults.set(teamNumber, forKey: "teamNumber")
        defaults.set(eventName, forKey: "widget_eventName")
        defaults.set(nextMatch, forKey: "widget_nextMatch")
        defaults.set(queueStatus, forKey: "widget_queueStatus")
        defaults.set(isEnglish ? "Just now" : "Az once", forKey: "widget_updatedAt")
        defaults.set(languageCode, forKey: "widget_languageCode")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
