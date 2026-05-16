import SwiftUI

/// Nexus `match.status` değerleri — https://frc.nexus/api/v1/docs
enum NexusQueueStatus {
    static let queuingSoon = "Queuing soon"
    static let nowQueuing = "Now queuing"
    static let onDeck = "On deck"
    static let onField = "On field"

    /// API'den gelen ham metni kanonik Nexus koduna indirger; bilinmeyen değerler olduğu gibi kalır.
    static func canonicalCode(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        let lower = trimmed.lowercased()
        if lower == "queuing soon" || lower.contains("queuing soon") { return queuingSoon }
        if lower == "now queuing" || lower.contains("now queuing") { return nowQueuing }
        if lower == "on deck" || lower.contains("on deck") { return onDeck }
        if lower == "on field" || lower.contains("on field") { return onField }
        return trimmed
    }

    static func displayText(_ raw: String, language: AppLanguage) -> String {
        switch canonicalCode(raw) {
        case queuingSoon:
            return L10n.text(.nexusStatusQueuingSoon, language: language)
        case nowQueuing:
            return L10n.text(.nexusStatusNowQueuing, language: language)
        case onDeck:
            return L10n.text(.nexusStatusOnDeck, language: language)
        case onField:
            return L10n.text(.nexusStatusOnField, language: language)
        default:
            return raw.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    static func shouldNotify(for raw: String) -> Bool {
        switch canonicalCode(raw) {
        case nowQueuing, onDeck, onField:
            return true
        default:
            return false
        }
    }

    static func accentColor(for raw: String) -> Color {
        switch canonicalCode(raw) {
        case queuingSoon:
            return .gray
        case nowQueuing:
            return .orange
        case onDeck:
            return Color(red: 0.92, green: 0.78, blue: 0.12)
        case onField:
            return .green
        default:
            return .secondary
        }
    }
}
