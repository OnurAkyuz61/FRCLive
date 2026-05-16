import Foundation
import SwiftUI

enum NexusFeedItemKind: String, Hashable, Codable {
    case announcement
    case partsRequest
    /// Maç programındaki `breakAfter: Alliance selection` verisinden (tüm takımlar).
    case allianceSelection
}

/// Nexus `announcements` içindeki otomatik/manuel alt türler (API'de ayrı alan yok; metinden çıkarılır).
enum NexusAnnouncementSubtype: String, Hashable, Codable {
    case general
    case replay
    case allianceSelection
}

struct NexusFeedItem: Identifiable, Hashable, Codable {
    let id: String
    let kind: NexusFeedItemKind
    let message: String
    let postedTimeMillis: Int64
    let requestedByTeam: String?
    let pitAddress: String?
    /// Yalnızca `kind == .announcement` için anlamlıdır.
    let announcementSubtype: NexusAnnouncementSubtype?
    /// İttifak seçimi: son sıralama maçı etiketi (ör. `Qualification 42`).
    let relatedMatchLabel: String?

    var postedDate: Date {
        Date(timeIntervalSince1970: TimeInterval(postedTimeMillis) / 1000.0)
    }

    var resolvedAnnouncementSubtype: NexusAnnouncementSubtype {
        announcementSubtype ?? .general
    }

    static func classifyAnnouncement(message: String, apiType: String? = nil) -> NexusAnnouncementSubtype {
        if let apiType, let parsed = subtype(fromAPIType: apiType) {
            return parsed
        }
        let lower = message.lowercased()
        if lower.range(of: #"\breplay\b"#, options: .regularExpression) != nil
            || lower.contains("replay of")
            || lower.contains("tekrar oynan") {
            return .replay
        }
        if lower.contains("alliance selection")
            || lower.contains("alliance-selection")
            || lower.contains("ittifak seçimi")
            || lower.contains("ittifak secimi")
            || (lower.contains("alliance") && lower.contains("selection"))
            || lower.contains("representatives for alliance") {
            return .allianceSelection
        }
        return .general
    }

    private static func subtype(fromAPIType type: String) -> NexusAnnouncementSubtype? {
        switch type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "replay", "matchreplay", "match_replay":
            return .replay
        case "allianceselection", "alliance_selection", "alliance", "selection":
            return .allianceSelection
        case "general", "event", "manual", "announcement":
            return .general
        default:
            return nil
        }
    }

    func categoryLabel(language: AppLanguage) -> String {
        switch kind {
        case .allianceSelection:
            return L10n.text(.announcementAllianceCategory, language: language)
        case .announcement:
            switch resolvedAnnouncementSubtype {
            case .general:
                return L10n.text(.announcementFromEvent, language: language)
            case .replay:
                return L10n.text(.announcementReplayCategory, language: language)
            case .allianceSelection:
                return L10n.text(.announcementAllianceCategory, language: language)
            }
        case .partsRequest:
            guard let team = requestedByTeam, !team.isEmpty else {
                return L10n.text(.partsRequestCategory, language: language)
            }
            if let pit = pitAddress, !pit.isEmpty {
                return String(format: L10n.text(.partsRequestCategoryWithTeamAndPit, language: language), team, pit)
            }
            return String(format: L10n.text(.partsRequestCategoryWithTeam, language: language), team)
        }
    }

    /// Liste satırı üst başlığı (bildirim türüyle aynı metinler).
    func listRowTitle(language: AppLanguage) -> String {
        switch kind {
        case .announcement:
            return categoryLabel(language: language)
        case .partsRequest:
            return detailTitle(language: language)
        }
    }

    /// Parça taleplerinde takım / pit alt satırı.
    func listRowSubtitle(language: AppLanguage) -> String? {
        if kind == .allianceSelection, let label = relatedMatchLabel, !label.isEmpty {
            return String(format: L10n.text(.allianceSelectionAfterMatch, language: language), label)
        }
        guard kind == .partsRequest else { return nil }
        guard let team = requestedByTeam, !team.isEmpty else { return nil }
        if let pit = pitAddress, !pit.isEmpty {
            return language == .en
                ? "Team \(team) • [\(pit)]"
                : "Takım \(team) • [\(pit)]"
        }
        return language == .en ? "Team \(team)" : "Takım \(team)"
    }

    func detailTitle(language: AppLanguage) -> String {
        switch kind {
        case .allianceSelection:
            return L10n.text(.announcementAllianceDetailTitle, language: language)
        case .announcement:
            switch resolvedAnnouncementSubtype {
            case .general:
                return L10n.text(.announcementDetailTitle, language: language)
            case .replay:
                return L10n.text(.announcementReplayDetailTitle, language: language)
            case .allianceSelection:
                return L10n.text(.announcementAllianceDetailTitle, language: language)
            }
        case .partsRequest:
            return L10n.text(.partsRequestDetailTitle, language: language)
        }
    }

    func notificationTypeKey() -> L10nKey {
        switch kind {
        case .allianceSelection:
            return .announcementAllianceNotificationTitle
        case .announcement:
            switch resolvedAnnouncementSubtype {
            case .general: return .announcementNotificationTitle
            case .replay: return .announcementReplayNotificationTitle
            case .allianceSelection: return .announcementAllianceNotificationTitle
            }
        case .partsRequest:
            return .partsRequestNotificationTitle
        }
    }

    func notificationTitle(language: AppLanguage) -> String {
        L10n.notificationHeader(notificationTypeKey(), language: language)
    }

    func iconName(processBlueDefault: String = "megaphone.fill") -> String {
        switch kind {
        case .allianceSelection:
            return "person.3.fill"
        case .announcement:
            switch resolvedAnnouncementSubtype {
            case .general:
                return processBlueDefault
            case .replay:
                return "arrow.counterclockwise.circle.fill"
            case .allianceSelection:
                return "person.3.fill"
            }
        case .partsRequest:
            return "wrench.and.screwdriver.fill"
        }
    }

    func accentColor(processBlue: Color) -> Color {
        switch kind {
        case .allianceSelection:
            return Color(red: 0.48, green: 0.32, blue: 0.78)
        case .announcement:
            switch resolvedAnnouncementSubtype {
            case .general:
                return processBlue
            case .replay:
                return Color(red: 0.92, green: 0.55, blue: 0.12)
            case .allianceSelection:
                return Color(red: 0.48, green: 0.32, blue: 0.78)
            }
        case .partsRequest:
            return Color(red: 0.42, green: 0.44, blue: 0.48)
        }
    }
}

// Geriye dönük uyumluluk
typealias NexusAnnouncement = NexusFeedItem
