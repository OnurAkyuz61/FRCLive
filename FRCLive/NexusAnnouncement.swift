import Foundation

enum NexusFeedItemKind: String, Hashable, Codable {
    case announcement
    case partsRequest
}

struct NexusFeedItem: Identifiable, Hashable, Codable {
    let id: String
    let kind: NexusFeedItemKind
    let message: String
    let postedTimeMillis: Int64
    let requestedByTeam: String?
    let pitAddress: String?

    var postedDate: Date {
        Date(timeIntervalSince1970: TimeInterval(postedTimeMillis) / 1000.0)
    }

    func categoryLabel(language: AppLanguage) -> String {
        switch kind {
        case .announcement:
            return L10n.text(.announcementFromEvent, language: language)
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
}

// Geriye dönük uyumluluk
typealias NexusAnnouncement = NexusFeedItem
