import Foundation
import WidgetKit

enum WidgetDataStore {
    // Enable this App Group in both app and widget targets:
    // group.onurakyuz.FRCLive
    static let appGroupID = "group.onurakyuz.FRCLive"

    static func writeSnapshot(
        teamNumber: String,
        teamName: String,
        eventName: String,
        nextMatch: String,
        currentOnField: String,
        queueStatus: String,
        queueStatusCode: String? = nil,
        updatedAt: String,
        languageCode: String
    ) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            debugLog("App Group unavailable in writeSnapshot.")
            return
        }
        defaults.set(teamNumber, forKey: "widget_teamNumber")
        defaults.set(teamName, forKey: "widget_teamName")
        defaults.set(eventName, forKey: "widget_eventName")
        defaults.set(nextMatch, forKey: "widget_nextMatch")
        defaults.set(currentOnField, forKey: "widget_currentOnField")
        defaults.set(queueStatus, forKey: "widget_queueStatus")
        let resolvedStatusCode = queueStatusCode ?? inferQueueStatusCode(from: queueStatus)
        defaults.set(resolvedStatusCode, forKey: "widget_queueStatusCode")
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
        let queueStatusCode: String
        let teamName: String

        if normalizedTeam.isEmpty {
            eventName = isEnglish ? "Please enter a team number" : "Lütfen bir takım numarası girin"
            nextMatch = "-"
            currentOnField = "-"
            queueStatus = isEnglish ? "Waiting for team selection" : "Takım seçimi bekleniyor"
            queueStatusCode = "waiting_team_selection"
            teamName = ""
        } else if normalizedEventCode.isEmpty {
            eventName = isEnglish ? "Please select an event" : "Lütfen bir etkinlik seçin"
            nextMatch = "-"
            currentOnField = "-"
            queueStatus = isEnglish ? "Waiting for event selection" : "Etkinlik seçimi bekleniyor"
            queueStatusCode = "waiting_event_selection"
            teamName = defaults.string(forKey: "widget_teamName") ?? ""
        } else {
            eventName = defaults.string(forKey: "widget_eventName") ?? (isEnglish ? "Loading..." : "Yükleniyor...")
            nextMatch = defaults.string(forKey: "widget_nextMatch") ?? "-"
            currentOnField = defaults.string(forKey: "widget_currentOnField") ?? "-"
            queueStatus = defaults.string(forKey: "widget_queueStatus") ?? (isEnglish ? "Loading live data..." : "Canlı veri yükleniyor...")
            queueStatusCode = defaults.string(forKey: "widget_queueStatusCode") ?? "loading_live_data"
            teamName = defaults.string(forKey: "widget_teamName") ?? ""
        }

        defaults.set(teamNumber, forKey: "widget_teamNumber")
        defaults.set(teamNumber, forKey: "teamNumber")
        defaults.set(teamName, forKey: "widget_teamName")
        defaults.set(eventName, forKey: "widget_eventName")
        defaults.set(nextMatch, forKey: "widget_nextMatch")
        defaults.set(currentOnField, forKey: "widget_currentOnField")
        defaults.set(queueStatus, forKey: "widget_queueStatus")
        defaults.set(queueStatusCode, forKey: "widget_queueStatusCode")
        defaults.set(currentTimeLabel(localeCode: isEnglish ? "en_US_POSIX" : "tr_TR"), forKey: "widget_updatedAt")
        defaults.set(languageCode, forKey: "widget_languageCode")
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func inferQueueStatusCode(from queueStatus: String) -> String {
        let lower = queueStatus.lowercased()
        if lower.contains("on field") || lower.contains("sahada") {
            return "On Field"
        }
        if lower.contains("called") || lower.contains("çağr") {
            if lower.contains("not called") || lower.contains("çağrılmadı") || lower.contains("henüz") {
                return "Not Called"
            }
            return "Called to Queue"
        }
        if lower.contains("not called") || lower.contains("henüz") {
            return "Not Called"
        }
        if lower.contains("waiting for team") || lower.contains("takım seçimi bekleniyor") {
            return "waiting_team_selection"
        }
        if lower.contains("waiting for event") || lower.contains("etkinlik seçimi bekleniyor") {
            return "waiting_event_selection"
        }
        if lower.contains("loading live data") || lower.contains("canlı veri yükleniyor") {
            return "loading_live_data"
        }
        return "Unknown"
    }

    private static func currentTimeLabel(localeCode: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeCode)
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }

    private static func debugLog(_ message: String) {
#if DEBUG
        print("[WidgetDataStore] \(message)")
#endif
    }
}
