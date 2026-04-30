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
        currentOnField: String,
        queueStatus: String,
        updatedAt: String,
        languageCode: String
    ) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            debugLog("App Group unavailable in writeSnapshot.")
            return
        }
        defaults.set(teamNumber, forKey: "widget_teamNumber")
        defaults.set(eventName, forKey: "widget_eventName")
        defaults.set(nextMatch, forKey: "widget_nextMatch")
        defaults.set(currentOnField, forKey: "widget_currentOnField")
        defaults.set(queueStatus, forKey: "widget_queueStatus")
        defaults.set(updatedAt, forKey: "widget_updatedAt")
        defaults.set(languageCode, forKey: "widget_languageCode")
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func syncAppState(teamNumber: String, selectedEventCode: String, languageCode: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            debugLog("App Group unavailable in syncAppState.")
            return
        }
        let isEnglish = languageCode == "en"

        let normalizedTeam = teamNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEventCode = selectedEventCode.trimmingCharacters(in: .whitespacesAndNewlines)

        let eventName: String
        let nextMatch: String
        let currentOnField: String
        let queueStatus: String

        if normalizedTeam.isEmpty {
            eventName = isEnglish ? "Please enter a team number" : "Lütfen bir takım numarası girin"
            nextMatch = "-"
            currentOnField = "-"
            queueStatus = isEnglish ? "Waiting for team selection" : "Takım seçimi bekleniyor"
        } else if normalizedEventCode.isEmpty {
            eventName = isEnglish ? "Please select an event" : "Lütfen bir etkinlik seçin"
            nextMatch = "-"
            currentOnField = "-"
            queueStatus = isEnglish ? "Waiting for event selection" : "Etkinlik seçimi bekleniyor"
        } else {
            eventName = defaults.string(forKey: "widget_eventName") ?? (isEnglish ? "Loading..." : "Yükleniyor...")
            nextMatch = defaults.string(forKey: "widget_nextMatch") ?? "-"
            currentOnField = defaults.string(forKey: "widget_currentOnField") ?? "-"
            queueStatus = defaults.string(forKey: "widget_queueStatus") ?? (isEnglish ? "Loading live data..." : "Canlı veri yükleniyor...")
        }

        defaults.set(teamNumber, forKey: "widget_teamNumber")
        defaults.set(teamNumber, forKey: "teamNumber")
        defaults.set(eventName, forKey: "widget_eventName")
        defaults.set(nextMatch, forKey: "widget_nextMatch")
        defaults.set(currentOnField, forKey: "widget_currentOnField")
        defaults.set(queueStatus, forKey: "widget_queueStatus")
        defaults.set(isEnglish ? "Just now" : "Az önce", forKey: "widget_updatedAt")
        defaults.set(languageCode, forKey: "widget_languageCode")
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func debugLog(_ message: String) {
#if DEBUG
        print("[WidgetDataStore] \(message)")
#endif
    }
}
