import Foundation
import SwiftUI

struct NexusTeamQueueSnapshot {
    let currentMatchOnField: String
    let teamNextMatch: String?
    let estimatedStartTime: String?
    /// Nexus `match.status` — örn. `Queuing soon`, `Now queuing`, `On deck`, `On field`
    let queuingStatus: String
}

struct NexusUpcomingQueueItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let estimatedQueueTime: String?
    let scheduledStartTime: String?
    let resumeMatchNumber: String?
    let redAlliance: [String]
    let blueAlliance: [String]
    let accentAlliance: NexusAllianceAccent
}

struct NexusQueuingBoardSnapshot {
    let divisionName: String?
    let currentMatchOnField: String
    let entries: [NexusUpcomingQueueItem]
}

enum NexusAllianceAccent {
    case red
    case blue
    case neutral
}

private struct NexusQueuingResponse: Decodable {
    let currentMatchOnField: String?
    let entries: [NexusQueueEntry]

    enum CodingKeys: String, CodingKey {
        case currentMatchOnField = "current_match_on_field"
        case currentMatch = "current_match"
        case entries
        case queue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let matchOnFieldPrimary = try container.decodeIfPresent(String.self, forKey: .currentMatchOnField)
        let matchOnFieldFallback = try container.decodeIfPresent(String.self, forKey: .currentMatch)
        currentMatchOnField = matchOnFieldPrimary ?? matchOnFieldFallback

        let directEntries = try container.decodeIfPresent([NexusQueueEntry].self, forKey: .entries)
        let queueEntries = try container.decodeIfPresent([NexusQueueEntry].self, forKey: .queue)
        entries = directEntries ?? queueEntries ?? []
    }
}

private struct NexusQueueEntry: Decodable {
    let teamNumber: Int
    let nextMatch: String?
    let estimatedStartTime: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case teamNumber = "team_number"
        case team
        case nextMatch = "team_next_match"
        case nextMatchAlt = "next_match"
        case estimatedStartTime = "estimated_start_time"
        case estimatedTimeAlt = "estimated_time"
        case status
        case queueStatus = "queuing_status"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let primaryTeamNumber = try container.decodeIfPresent(Int.self, forKey: .teamNumber)
        let fallbackTeamNumber = try container.decodeIfPresent(Int.self, forKey: .team)
        guard let resolvedTeamNumber = primaryTeamNumber ?? fallbackTeamNumber else {
            throw NexusAPIClientError.invalidResponse
        }
        teamNumber = resolvedTeamNumber

        let primaryNextMatch = try container.decodeIfPresent(String.self, forKey: .nextMatch)
        let fallbackNextMatch = try container.decodeIfPresent(String.self, forKey: .nextMatchAlt)
        nextMatch = primaryNextMatch ?? fallbackNextMatch

        let primaryEstimated = try container.decodeIfPresent(String.self, forKey: .estimatedStartTime)
        let fallbackEstimated = try container.decodeIfPresent(String.self, forKey: .estimatedTimeAlt)
        estimatedStartTime = primaryEstimated ?? fallbackEstimated

        let primaryStatus = try container.decodeIfPresent(String.self, forKey: .queueStatus)
        let fallbackStatus = try container.decodeIfPresent(String.self, forKey: .status)
        status = primaryStatus ?? fallbackStatus ?? ""
    }
}

enum NexusAPIClientError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case teamNotFoundInQueue
    case unauthorized
    case eventNotFound
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidRequest, .invalidResponse:
            return "Canlı veri alınamadı."
        case .teamNotFoundInQueue:
            return "Sıradaki maç bulunamadı."
        case .unauthorized:
            return "Nexus API anahtarı geçersiz veya eksik."
        case .eventNotFound:
            return "Bu etkinlik için Nexus kuyruk verisi bulunamadı."
        case .serviceUnavailable:
            return "Nexus servisi şu anda kullanılamıyor."
        }
    }
}

final class NexusAPIClient {
    static let shared = NexusAPIClient()
    static let nexusApiKeyStorageKey = "nexusApiKey"
    private let demoTeamNumber = 99999
    private let defaultNexusApiKey = "HfG4EGZoOR6gUdof2-gtqNU3I8E"
    private var cachedEventsIndex: [String: String] = [:]
    private var cachedEventsIndexDate: Date?
    private let eventsIndexCacheTTL: TimeInterval = 300
    private init() {}

    func persistedNexusApiKey() -> String {
        UserDefaults.standard.string(forKey: Self.nexusApiKeyStorageKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func saveNexusApiKey(_ value: String) {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        UserDefaults.standard.set(cleaned, forKey: Self.nexusApiKeyStorageKey)
    }

    func clearNexusApiKey() {
        UserDefaults.standard.removeObject(forKey: Self.nexusApiKeyStorageKey)
    }

    func validateNexusApiKey(_ value: String) async throws {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw NexusAPIClientError.unauthorized
        }
        guard let url = URL(string: "https://frc.nexus/api/v1/events") else {
            throw NexusAPIClientError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue(cleaned, forHTTPHeaderField: "Nexus-Api-Key")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NexusAPIClientError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return
        case 401, 403:
            throw NexusAPIClientError.unauthorized
        case 502, 503, 504:
            throw NexusAPIClientError.serviceUnavailable
        default:
            throw NexusAPIClientError.invalidResponse
        }
    }

    private var nexusApiKey: String {
        let stored = UserDefaults.standard.string(forKey: Self.nexusApiKeyStorageKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let stored, !stored.isEmpty {
            return stored
        }
        return defaultNexusApiKey
    }

    func fetchQueueSnapshot(eventCode: String, teamNumber: Int) async throws -> NexusTeamQueueSnapshot {
        if teamNumber == demoTeamNumber {
            return NexusTeamQueueSnapshot(
                currentMatchOnField: "Qual 34",
                teamNextMatch: "Qual 42",
                estimatedStartTime: "10 dk",
                queuingStatus: NexusQueueStatus.onDeck
            )
        }

        let (data, _, resolvedEventCode) = try await fetchQueuingPayload(eventCode: eventCode)
        debugLog("Queue status=200 event=\(resolvedEventCode) team=\(teamNumber)")
        let liveEvent = try parseLiveEventPayload(data: data)
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let currentOnField = resolveCurrentOnFieldLabel(matches: liveEvent.matches, nowMilliseconds: nowMs)
        let current = currentOnField ?? liveEvent.latestMatchLabel ?? "-"

        guard let teamMatch = prioritizedMatch(
            for: teamNumber,
            matches: liveEvent.matches,
            currentMatchLabel: currentOnField ?? liveEvent.latestMatchLabel
        ) else {
            return NexusTeamQueueSnapshot(
                currentMatchOnField: current,
                teamNextMatch: nil,
                estimatedStartTime: nil,
                queuingStatus: ""
            )
        }

        return NexusTeamQueueSnapshot(
            currentMatchOnField: current,
            teamNextMatch: teamMatch.label,
            estimatedStartTime: formatMillisToTime(teamMatch.times.estimatedStartTimeMillis),
            queuingStatus: teamMatch.status
        )
    }

    func fetchEventFeed(
        eventCode: String,
        teamNumber: String,
        language: AppLanguage
    ) async throws -> [NexusFeedItem] {
        if teamNumber == String(demoTeamNumber) {
            return Self.demoEventFeed(language: language)
        }

        let (data, _, resolvedCode) = try await fetchQueuingPayload(eventCode: eventCode)
        let liveEvent = try parseLiveEventPayload(data: data)
        let pitMap = (try? await fetchPitAddressMap(eventCode: resolvedCode)) ?? [:]
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let currentOnField = resolveCurrentOnFieldLabel(matches: liveEvent.matches, nowMilliseconds: nowMs)
        let allianceItem = buildAllianceSelectionFeedItem(
            matches: liveEvent.matches,
            currentLabel: currentOnField ?? liveEvent.latestMatchLabel,
            language: language
        )
        return mergeEventFeed(
            announcements: liveEvent.announcements,
            partsRequests: liveEvent.partsRequests,
            allianceSelection: allianceItem,
            pitMap: pitMap
        )
    }

    /// Geriye dönük isim.
    func fetchAnnouncements(
        eventCode: String,
        teamNumber: String,
        language: AppLanguage
    ) async throws -> [NexusFeedItem] {
        try await fetchEventFeed(eventCode: eventCode, teamNumber: teamNumber, language: language)
    }

    static func demoEventFeed(now: Date = Date(), language: AppLanguage = .tr) -> [NexusFeedItem] {
        let nowMs = Int64(now.timeIntervalSince1970 * 1000)
        let hour: Int64 = 3_600_000
        let announcements: [(String, NexusAnnouncementSubtype)] = [
            ("Sürücü toplantısı saat 09:00'da ana sahada başlayacak.", .general),
            ("A replay of Qualification 2 will be the first match played after lunch", .replay)
        ]
        let allianceLabel = language == .en ? "Qualification 42" : "Sıralama 42"
        let parts: [(String, String, String)] = [
            ("REV absolute encoder adaptor for swerve", "2480", "A6"),
            ("375mm x 9mm HTD belt", "2472", "A5"),
            ("safety side shields", "3082", "C1")
        ]

        var items: [NexusFeedItem] = announcements.enumerated().map { index, entry in
            NexusFeedItem(
                id: "demo-announcement-\(index)",
                kind: .announcement,
                message: entry.0,
                postedTimeMillis: nowMs - Int64(index + 1) * hour,
                requestedByTeam: nil,
                pitAddress: nil,
                announcementSubtype: entry.1,
                relatedMatchLabel: nil
            )
        }
        items.append(
            NexusFeedItem(
                id: "demo-alliance-selection",
                kind: .allianceSelection,
                message: String(format: L10n.text(.allianceSelectionMessage, language: language), allianceLabel, allianceLabel),
                postedTimeMillis: nowMs - 15 * 60 * 1000,
                requestedByTeam: nil,
                pitAddress: nil,
                announcementSubtype: nil,
                relatedMatchLabel: allianceLabel
            )
        )
        items += parts.enumerated().map { index, entry in
            NexusFeedItem(
                id: "demo-parts-\(index)",
                kind: .partsRequest,
                message: entry.0,
                postedTimeMillis: nowMs - Int64(index + 1) * 45 * 60 * 1000,
                requestedByTeam: entry.1,
                pitAddress: entry.2,
                announcementSubtype: nil,
                relatedMatchLabel: nil
            )
        }
        return items.sorted { $0.postedTimeMillis > $1.postedTimeMillis }
    }

    private func mergeEventFeed(
        announcements: [NexusFeedItem],
        partsRequests: [NexusFeedItem],
        allianceSelection: NexusFeedItem?,
        pitMap: [String: String]
    ) -> [NexusFeedItem] {
        let enrichedParts = partsRequests.map { item -> NexusFeedItem in
            guard item.kind == .partsRequest,
                  let team = item.requestedByTeam,
                  item.pitAddress == nil,
                  let pit = pitMap[team] else {
                return item
            }
            return NexusFeedItem(
                id: item.id,
                kind: item.kind,
                message: item.message,
                postedTimeMillis: item.postedTimeMillis,
                requestedByTeam: item.requestedByTeam,
                pitAddress: pit,
                announcementSubtype: item.announcementSubtype,
                relatedMatchLabel: item.relatedMatchLabel
            )
        }
        var items = announcements + enrichedParts
        if let allianceSelection,
           !feedAlreadyCoversAllianceSelection(announcements, anchorLabel: allianceSelection.relatedMatchLabel) {
            items.append(allianceSelection)
        }
        return items.sorted { $0.postedTimeMillis > $1.postedTimeMillis }
    }

    private func feedAlreadyCoversAllianceSelection(_ announcements: [NexusFeedItem], anchorLabel: String?) -> Bool {
        announcements.contains { item in
            if item.kind == .allianceSelection { return true }
            if item.kind == .announcement, item.resolvedAnnouncementSubtype == .allianceSelection {
                return true
            }
            return false
        }
    }

    private func buildAllianceSelectionFeedItem(
        matches: [NexusLiveMatch],
        currentLabel: String?,
        language: AppLanguage
    ) -> NexusFeedItem? {
        guard let anchor = matches.last(where: { match in
            guard let breakAfter = match.breakAfter?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                  breakAfter == "alliance selection" else {
                return false
            }
            return phaseRank(from: match.label) == 2
        }) else {
            return nil
        }

        guard shouldShowAllianceSelectionNotice(anchor: anchor, matches: matches, currentLabel: currentLabel) else {
            return nil
        }

        let label = anchor.label
        let postedTime = anchor.times.estimatedOnDeckTimeMillis
            ?? anchor.times.estimatedOnFieldTimeMillis
            ?? anchor.times.estimatedQueueTimeMillis
            ?? Int64(Date().timeIntervalSince1970 * 1000)

        return NexusFeedItem(
            id: "nexus-alliance-selection-\(label)",
            kind: .allianceSelection,
            message: String(format: L10n.text(.allianceSelectionMessage, language: language), label, label),
            postedTimeMillis: postedTime,
            requestedByTeam: nil,
            pitAddress: nil,
            announcementSubtype: nil,
            relatedMatchLabel: label
        )
    }

    private func shouldShowAllianceSelectionNotice(
        anchor: NexusLiveMatch,
        matches: [NexusLiveMatch],
        currentLabel: String?
    ) -> Bool {
        if hasPlayoffsUnderway(matches) { return false }

        let anchorStatus = anchor.status.lowercased()
        if anchorStatus.contains("on deck") || anchorStatus.contains("on field") || anchorStatus.contains("now queuing") {
            return true
        }

        if let currentLabel {
            if currentLabel == anchor.label { return true }
            if let currentOrder = matchOrder(from: currentLabel),
               let anchorOrder = matchOrder(from: anchor.label) {
                if currentOrder.phase > anchorOrder.phase { return true }
                if currentOrder.phase == anchorOrder.phase, currentOrder.number >= anchorOrder.number {
                    return true
                }
            }
        }

        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let remainingQuals = matches.filter { match in
            phaseRank(from: match.label) == 2 && isUpcomingMatch(match, nowMilliseconds: nowMs)
        }
        return remainingQuals.isEmpty
    }

    private func hasPlayoffsUnderway(_ matches: [NexusLiveMatch]) -> Bool {
        matches.contains { match in
            guard phaseRank(from: match.label) >= 3 else { return false }
            let status = match.status.lowercased()
            return status.contains("on field")
                || status.contains("on deck")
                || status.contains("now queuing")
        }
    }

    private func fetchPitAddressMap(eventCode: String) async throws -> [String: String] {
        let apiKey = nexusApiKey
        for candidate in await resolvedEventCandidates(from: eventCode, apiKey: apiKey) {
            guard let url = URL(string: "https://frc.nexus/api/v1/event/\(candidate)/pits") else { continue }
            var request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "Nexus-Api-Key")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { continue }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
            var map: [String: String] = [:]
            for (key, value) in json {
                if let address = value as? String, !address.isEmpty {
                    map[key] = address
                }
            }
            if !map.isEmpty { return map }
        }
        return [:]
    }

    func fetchQueuingBoard(eventCode: String, teamNumber: Int) async throws -> NexusQueuingBoardSnapshot {
        if teamNumber == demoTeamNumber {
            return NexusQueuingBoardSnapshot(
                divisionName: "Johnson Division",
                currentMatchOnField: "Sıralama 9",
                entries: [
                    NexusUpcomingQueueItem(
                        id: "demo-1",
                        title: "Sıralama 10",
                        subtitle: "16:48",
                        estimatedQueueTime: "16:48",
                        scheduledStartTime: "17:12",
                        resumeMatchNumber: "11",
                        redAlliance: ["10396", "245", "9072"],
                        blueAlliance: ["836", "9483", "1306"],
                        accentAlliance: .blue
                    ),
                    NexusUpcomingQueueItem(
                        id: "demo-2",
                        title: "Sıralama 24",
                        subtitle: "18:40",
                        estimatedQueueTime: "18:40",
                        scheduledStartTime: nil,
                        resumeMatchNumber: "25",
                        redAlliance: ["598", "3492", "2714"],
                        blueAlliance: ["9483", "118", "6924"],
                        accentAlliance: .blue
                    ),
                    NexusUpcomingQueueItem(
                        id: "demo-break",
                        title: "Öğle Arası",
                        subtitle: "Sıralama 31 sonrasında",
                        estimatedQueueTime: nil,
                        scheduledStartTime: nil,
                        resumeMatchNumber: "31",
                        redAlliance: [],
                        blueAlliance: [],
                        accentAlliance: .neutral
                    ),
                    NexusUpcomingQueueItem(
                        id: "demo-3",
                        title: "Sıralama 35",
                        subtitle: "21:49",
                        estimatedQueueTime: "21:49",
                        scheduledStartTime: nil,
                        resumeMatchNumber: "36",
                        redAlliance: ["9483", "3316", "7734"],
                        blueAlliance: ["1622", "6405", "4632"],
                        accentAlliance: .red
                    )
                ]
            )
        }

        let (data, _, _) = try await fetchQueuingPayload(eventCode: eventCode)
        let liveEvent = try parseLiveEventPayload(data: data)
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let currentOnField = resolveCurrentOnFieldLabel(matches: liveEvent.matches, nowMilliseconds: nowMs)
        let currentLabel = currentOnField ?? liveEvent.latestMatchLabel

        var teamOnlyMatches = teamUpcomingMatchesForBoard(
            matches: liveEvent.matches,
            teamNumber: teamNumber,
            currentLabel: currentLabel,
            nowMilliseconds: nowMs
        )
        if teamOnlyMatches.isEmpty,
           currentLabel == nil || matchOrder(from: currentLabel) == nil,
           let fallback = prioritizedMatch(
            for: teamNumber,
            matches: liveEvent.matches,
            currentMatchLabel: currentLabel
           ) {
            teamOnlyMatches = [fallback]
        }
        let teamNumberString = String(teamNumber)

        var parsedEntries: [NexusUpcomingQueueItem] = []
        var previousMatch: NexusLiveMatch?

        for (index, match) in teamOnlyMatches.enumerated() {
            if let previousMatch,
               let breakItem = syntheticBreakItemIfNeeded(before: match, after: previousMatch, index: index) {
                parsedEntries.append(breakItem)
            }

            let accent: NexusAllianceAccent
            if match.redTeams.contains(teamNumberString) {
                accent = .red
            } else if match.blueTeams.contains(teamNumberString) {
                accent = .blue
            } else {
                accent = .neutral
            }

            let queueTimeText = formatMillisToTime(match.times.estimatedQueueTimeMillis)
            let subtitle = queueTimeText

            parsedEntries.append(NexusUpcomingQueueItem(
                id: "\(match.label)-\(index)",
                title: match.label,
                subtitle: subtitle,
                estimatedQueueTime: queueTimeText,
                scheduledStartTime: formatMillisToTime(match.times.estimatedStartTimeMillis),
                resumeMatchNumber: extractTrailingMatchNumber(from: match.label),
                redAlliance: match.redTeams,
                blueAlliance: match.blueTeams,
                accentAlliance: accent
            ))
            previousMatch = match
        }

        return NexusQueuingBoardSnapshot(
            divisionName: liveEvent.eventName,
            currentMatchOnField: currentLabel ?? liveEvent.latestMatchLabel ?? "-",
            entries: parsedEntries
        )
    }

    /// Takımın Nexus kuyruğundaki yaklaşan maçları (Ana sayfa / Sıradaki Maç listesi).
    private func teamUpcomingMatchesForBoard(
        matches: [NexusLiveMatch],
        teamNumber: Int,
        currentLabel: String?,
        nowMilliseconds: Int64
    ) -> [NexusLiveMatch] {
        let key = String(teamNumber)
        let teamMatches = matches.filter { match in
            !isBreakMatch(match)
                && (match.redTeams.contains(key) || match.blueTeams.contains(key))
        }
        guard !teamMatches.isEmpty else { return [] }

        let scheduleRelevant = teamMatches.filter { match in
            isRelevantTeamBoardMatch(match, currentLabel: currentLabel, nowMilliseconds: nowMilliseconds)
        }

        let forward = filterForwardFromCurrent(matches: scheduleRelevant, currentLabel: currentLabel)
        if !forward.isEmpty {
            return Array(sortMatchesBySchedule(forward).prefix(12))
        }
        // Sıralama/playoff sahadaysa ve takımın ileri maçı yoksa pratik maçlara dönme.
        if currentLabel != nil, matchOrder(from: currentLabel) != nil {
            return []
        }
        return Array(sortMatchesBySchedule(scheduleRelevant).prefix(12))
    }

    /// Zaman damgası eski olsa bile, sahadaki maçtan sonraki takım maçlarını göster.
    private func isRelevantTeamBoardMatch(
        _ match: NexusLiveMatch,
        currentLabel: String?,
        nowMilliseconds: Int64
    ) -> Bool {
        if isClearlyCompletedMatch(match) { return false }
        if !isAtOrAfterFieldProgress(match, currentLabel: currentLabel) { return false }
        if isUpcomingMatch(match, nowMilliseconds: nowMilliseconds) { return true }
        return isForwardOfCurrentField(match, currentLabel: currentLabel)
    }

    /// Sahadaki maçtan önceki fazları (ör. sıralama varken pratik) listeden çıkar.
    private func isAtOrAfterFieldProgress(_ match: NexusLiveMatch, currentLabel: String?) -> Bool {
        guard let currentLabel, let currentOrder = matchOrder(from: currentLabel),
              let order = matchOrder(from: match.label) else {
            return true
        }
        return order.phase >= currentOrder.phase
    }

    private func isClearlyCompletedMatch(_ match: NexusLiveMatch) -> Bool {
        let status = match.status.lowercased()
        return status.contains("completed") || status.contains("played")
    }

    private func isForwardOfCurrentField(_ match: NexusLiveMatch, currentLabel: String?) -> Bool {
        guard let currentLabel, let currentOrder = matchOrder(from: currentLabel),
              let order = matchOrder(from: match.label) else {
            return false
        }
        if order.phase != currentOrder.phase {
            return order.phase > currentOrder.phase
        }
        return order.number > currentOrder.number
    }

    private func filterForwardFromCurrent(matches: [NexusLiveMatch], currentLabel: String?) -> [NexusLiveMatch] {
        guard let currentLabel, let currentOrder = matchOrder(from: currentLabel) else {
            return matches
        }
        return matches.filter { match in
            guard let order = matchOrder(from: match.label) else { return true }
            if order.phase != currentOrder.phase {
                return order.phase > currentOrder.phase
            }
            return order.number > currentOrder.number
        }
    }

    private func sortMatchesBySchedule(_ matches: [NexusLiveMatch]) -> [NexusLiveMatch] {
        matches.sorted { lhs, rhs in
            let lhsTime = relevantTimeMillis(for: lhs)
            let rhsTime = relevantTimeMillis(for: rhs)
            if let lhsTime, let rhsTime, lhsTime != rhsTime {
                return lhsTime < rhsTime
            }
            if lhsTime != nil, rhsTime == nil { return true }
            if lhsTime == nil, rhsTime != nil { return false }

            guard let lhsOrder = matchOrder(from: lhs.label),
                  let rhsOrder = matchOrder(from: rhs.label) else {
                return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }
            if lhsOrder.phase != rhsOrder.phase { return lhsOrder.phase < rhsOrder.phase }
            return lhsOrder.number < rhsOrder.number
        }
    }

    private func relevantTimeMillis(for match: NexusLiveMatch) -> Int64? {
        match.times.estimatedQueueTimeMillis
            ?? match.times.estimatedOnDeckTimeMillis
            ?? match.times.estimatedOnFieldTimeMillis
            ?? match.times.estimatedStartTimeMillis
    }

    private func localCalendarDay(for milliseconds: Int64) -> Date? {
        let date = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000.0)
        return Calendar.current.startOfDay(for: date)
    }

    private func fetchQueuingPayload(eventCode: String) async throws -> (Data, HTTPURLResponse, String) {
        let apiKey = nexusApiKey
        let normalizedCandidates = await resolvedEventCandidates(from: eventCode, apiKey: apiKey)
        var sawUnauthorized = false
        var sawNotFound = false
        var sawServiceUnavailable = false
        var lastStatusCode: Int?

        for candidate in normalizedCandidates {
            guard let url = URL(string: "https://frc.nexus/api/v1/event/\(candidate)") else {
                continue
            }

            var request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "Nexus-Api-Key")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                continue
            }

            lastStatusCode = httpResponse.statusCode
            debugLog("Queue status=\(httpResponse.statusCode) event=\(candidate)")

            if httpResponse.statusCode == 200 {
                return (data, httpResponse, candidate)
            }

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                sawUnauthorized = true
                continue
            }
            if httpResponse.statusCode == 404 {
                sawNotFound = true
                continue
            }
            if httpResponse.statusCode == 502 || httpResponse.statusCode == 503 || httpResponse.statusCode == 504 {
                sawServiceUnavailable = true
                continue
            }
        }

        if sawNotFound {
            throw NexusAPIClientError.eventNotFound
        }
        if sawUnauthorized {
            throw NexusAPIClientError.unauthorized
        }
        if sawServiceUnavailable {
            throw NexusAPIClientError.serviceUnavailable
        }
        debugLog("Queue unresolved status last=\(lastStatusCode.map(String.init) ?? "nil") candidates=\(normalizedCandidates.joined(separator: ","))")
        throw NexusAPIClientError.invalidResponse
    }

    private func resolvedEventCandidates(from eventCode: String, apiKey: String) async -> [String] {
        var candidates = candidateEventCodes(from: eventCode)

        guard let selectedEventName = UserDefaults.standard.string(forKey: "selectedEventName")?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !selectedEventName.isEmpty else {
            return candidates
        }

        guard let eventsIndex = try? await fetchEventsIndex(apiKey: apiKey) else {
            return candidates
        }

        let normalizedSelected = selectedEventName.lowercased()
        let matchedKeys = eventsIndex.compactMap { key, name -> String? in
            let n = name.lowercased()
            if n == normalizedSelected || n.contains(normalizedSelected) || normalizedSelected.contains(n) {
                return key
            }
            return nil
        }

        candidates.append(contentsOf: matchedKeys)
        return Array(NSOrderedSet(array: candidates)) as? [String] ?? candidates
    }

    private func fetchEventsIndex(apiKey: String) async throws -> [String: String] {
        if let cachedDate = cachedEventsIndexDate,
           Date().timeIntervalSince(cachedDate) < eventsIndexCacheTTL,
           !cachedEventsIndex.isEmpty {
            return cachedEventsIndex
        }

        guard let url = URL(string: "https://frc.nexus/api/v1/events") else {
            throw NexusAPIClientError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "Nexus-Api-Key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NexusAPIClientError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw NexusAPIClientError.unauthorized
            }
            throw NexusAPIClientError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NexusAPIClientError.invalidResponse
        }

        var resolved: [String: String] = [:]
        for (key, value) in json {
            guard let object = value as? [String: Any],
                  let name = object["name"] as? String else {
                continue
            }
            resolved[key] = name
        }

        cachedEventsIndex = resolved
        cachedEventsIndexDate = Date()
        return resolved
    }

    private func candidateEventCodes(from eventCode: String) -> [String] {
        var candidates: [String] = []
        let trimmed = eventCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            candidates.append(trimmed)
        }

        return Array(NSOrderedSet(array: candidates)) as? [String] ?? candidates
    }

    private func parseLiveEventPayload(data: Data) throws -> NexusLiveEventPayload {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NexusAPIClientError.invalidResponse
        }

        let latestMatchLabel = (json["nowQueuing"] as? String) ?? (json["latestMatchLabel"] as? String)
        let eventName = json["eventName"] as? String
        let matchArray = json["matches"] as? [[String: Any]] ?? []
        let matches = matchArray.compactMap(parseLiveMatch)
        let announcementArray = json["announcements"] as? [[String: Any]] ?? []
        let announcements = announcementArray.compactMap(parseAnnouncement)
        let partsArray = json["partsRequests"] as? [[String: Any]] ?? []
        let partsRequests = partsArray.compactMap(parsePartsRequest)

        return NexusLiveEventPayload(
            latestMatchLabel: latestMatchLabel,
            eventName: eventName,
            matches: matches,
            announcements: announcements,
            partsRequests: partsRequests
        )
    }

    private func parseAnnouncement(raw: [String: Any]) -> NexusFeedItem? {
        guard let id = raw["id"] as? String, !id.isEmpty else { return nil }
        let message = parseFeedMessage(raw, primaryKey: "announcement", fallbacks: ["message", "text"])
        guard !message.isEmpty else { return nil }
        let postedTime = int64Value(raw["postedTime"]) ?? 0
        let apiType = (raw["type"] as? String) ?? (raw["announcementType"] as? String)
        let subtype = NexusFeedItem.classifyAnnouncement(message: message, apiType: apiType)
        return NexusFeedItem(
            id: id,
            kind: .announcement,
            message: message,
            postedTimeMillis: postedTime,
            requestedByTeam: nil,
            pitAddress: nil,
            announcementSubtype: subtype,
            relatedMatchLabel: nil
        )
    }

    private func parsePartsRequest(raw: [String: Any]) -> NexusFeedItem? {
        guard let id = raw["id"] as? String, !id.isEmpty else { return nil }
        let message = parseFeedMessage(raw, primaryKey: "parts", fallbacks: ["message", "text", "description"])
        guard !message.isEmpty else { return nil }
        let postedTime = int64Value(raw["postedTime"]) ?? 0
        let team = parseTeamNumberString(raw["requestedByTeam"])
        return NexusFeedItem(
            id: id,
            kind: .partsRequest,
            message: message,
            postedTimeMillis: postedTime,
            requestedByTeam: team,
            pitAddress: nil,
            announcementSubtype: nil,
            relatedMatchLabel: nil
        )
    }

    private func parseFeedMessage(_ raw: [String: Any], primaryKey: String, fallbacks: [String]) -> String {
        let candidates = [primaryKey] + fallbacks
        for key in candidates {
            if let value = raw[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
        }
        return ""
    }

    private func parseTeamNumberString(_ value: Any?) -> String? {
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let int = value as? Int { return String(int) }
        if let number = value as? NSNumber { return number.stringValue }
        return nil
    }

    private func parseLiveMatch(raw: [String: Any]) -> NexusLiveMatch? {
        guard let label = raw["label"] as? String, !label.isEmpty else {
            return nil
        }
        let status = (raw["status"] as? String) ?? "Unknown"
        let redTeams = parseTeamNumbers(from: raw, key: "redTeams")
        let blueTeams = parseTeamNumbers(from: raw, key: "blueTeams")
        let timesRaw = raw["times"] as? [String: Any] ?? [:]

        let breakAfter = raw["breakAfter"] as? String

        return NexusLiveMatch(
            label: label,
            status: status,
            breakAfter: breakAfter,
            redTeams: redTeams,
            blueTeams: blueTeams,
            times: NexusLiveMatchTimes(
                estimatedQueueTimeMillis: int64Value(timesRaw["estimatedQueueTime"]),
                estimatedOnDeckTimeMillis: int64Value(timesRaw["estimatedOnDeckTime"]),
                estimatedOnFieldTimeMillis: int64Value(timesRaw["estimatedOnFieldTime"]),
                estimatedStartTimeMillis: int64Value(timesRaw["estimatedStartTime"])
            )
        )
    }

    /// Takım şu an sahada oynanan maçtaysa o maçı döndür (Nexus “Sahada” davranışı).
    private func teamMatchAtCurrentField(
        teamMatches: [NexusLiveMatch],
        currentMatchLabel: String?
    ) -> NexusLiveMatch? {
        guard let currentMatchLabel, let currentOrder = matchOrder(from: currentMatchLabel) else {
            return nil
        }
        return teamMatches.first { match in
            guard !isClearlyCompletedMatch(match),
                  let order = matchOrder(from: match.label) else { return false }
            return order.phase == currentOrder.phase && order.number == currentOrder.number
        }
    }

    private func prioritizedMatch(for teamNumber: Int, matches: [NexusLiveMatch], currentMatchLabel: String?) -> NexusLiveMatch? {
        let key = String(teamNumber)
        let teamMatches = matches.filter { $0.redTeams.contains(key) || $0.blueTeams.contains(key) }
        guard !teamMatches.isEmpty else { return nil }

        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let currentOrder = matchOrder(from: currentMatchLabel)

        if let playingNow = teamMatchAtCurrentField(teamMatches: teamMatches, currentMatchLabel: currentMatchLabel) {
            return playingNow
        }

        let candidates = teamMatches.filter { match in
            !isClearlyCompletedMatch(match)
                && isAtOrAfterFieldProgress(match, currentLabel: currentMatchLabel)
                && (isUpcomingMatch(match, nowMilliseconds: nowMs)
                    || isForwardOfCurrentField(match, currentLabel: currentMatchLabel))
        }

        if let currentOrder {
            let forwardMatches = candidates.filter { match in
                guard let order = matchOrder(from: match.label) else { return false }
                if order.phase != currentOrder.phase {
                    return order.phase > currentOrder.phase
                }
                return order.number > currentOrder.number
            }

            if let nearestForward = sortMatchesBySchedule(forwardMatches).first {
                return nearestForward
            }
            // Takımın bu fazda ileri maçı kalmadı — Practice 1'e geri sarma.
            return nil
        }

        guard !candidates.isEmpty else { return nil }
        return sortMatchesBySchedule(candidates).first
    }

    private struct MatchOrder {
        let phase: Int
        let number: Int
    }

    private func matchOrder(from label: String?) -> MatchOrder? {
        guard let label else { return nil }
        let phase = phaseRank(from: label)
        guard phase > 0 else { return nil }
        guard let numberText = extractTrailingMatchNumber(from: label),
              let number = Int(numberText) else { return nil }
        return MatchOrder(phase: phase, number: number)
    }

    private func isUpcomingMatch(_ match: NexusLiveMatch, nowMilliseconds: Int64) -> Bool {
        let lowerStatus = match.status.lowercased()
        if isBreakLabel(match.label) {
            return true
        }
        if lowerStatus.contains("completed") || lowerStatus.contains("played") {
            return false
        }

        let time = match.times.estimatedQueueTimeMillis
            ?? match.times.estimatedOnDeckTimeMillis
            ?? match.times.estimatedOnFieldTimeMillis
            ?? match.times.estimatedStartTimeMillis

        if let time {
            // Hard cutoff: if match timing is clearly in the past, treat it as finished.
            return time >= nowMilliseconds - 10 * 60 * 1000
        }

        // If no timing info exists, fallback to status-based inclusion.
        if lowerStatus.contains("on field") || lowerStatus.contains("on deck") || lowerStatus.contains("now queuing") || lowerStatus.contains("queuing soon") {
            return true
        }
        return false
    }

    private func phaseRank(from label: String) -> Int {
        let normalized = label.lowercased()
        if normalized.contains("lunch") || normalized.contains("öğle") || normalized.contains("gun sonu") || normalized.contains("gün sonu") || normalized.contains("day end") {
            return 99
        }
        if normalized.contains("final") || normalized.contains("playoff") || normalized.contains("qf") || normalized.contains("sf") {
            return 3
        }
        if normalized.contains("qualification") || normalized.contains("qual") || normalized.contains("qm")
            || normalized.contains("sıralama") || normalized.contains("siralama") {
            return 2
        }
        if normalized.contains("practice") || normalized.contains("pm") || normalized.contains("pr") {
            return 1
        }
        return 0
    }

    private func isBreakMatch(_ match: NexusLiveMatch) -> Bool {
        isBreakLabel(match.label)
    }

    private func isBreakLabel(_ label: String) -> Bool {
        let normalized = label.lowercased()
        return normalized.contains("lunch")
            || normalized.contains("öğle")
            || normalized.contains("gun sonu")
            || normalized.contains("gün sonu")
            || normalized.contains("day end")
            || normalized.contains("break")
    }

    private func syntheticBreakItemIfNeeded(before next: NexusLiveMatch, after previous: NexusLiveMatch, index: Int) -> NexusUpcomingQueueItem? {
        let nextStart = next.times.estimatedStartTimeMillis ?? next.times.estimatedOnFieldTimeMillis
        let prevStart = previous.times.estimatedStartTimeMillis ?? previous.times.estimatedOnFieldTimeMillis
        guard let nextStart, let prevStart else { return nil }
        guard nextStart > prevStart else { return nil }

        let gap = nextStart - prevStart
        let title: String
        if gap >= 6 * 60 * 60 * 1000 {
            // Gece yarısı sonrası ertesi günün eleme maçları için yapay "Gün Sonu" satırı ekleme.
            if let prevDay = localCalendarDay(for: prevStart),
               let nextDay = localCalendarDay(for: nextStart),
               prevDay != nextDay {
                return nil
            }
            title = "Day End"
        } else if gap >= 130 * 60 * 1000 && gap <= 220 * 60 * 1000 {
            title = "Lunch Break"
        } else {
            return nil
        }

        let nextStartText = formatMillisToTime(nextStart) ?? "-"
        return NexusUpcomingQueueItem(
            id: "synthetic-break-\(index)-\(nextStart)",
            title: title,
            subtitle: breakSubtitle(after: previous.label),
            estimatedQueueTime: nil,
            scheduledStartTime: nextStartText,
            resumeMatchNumber: extractTrailingMatchNumber(from: next.label),
            redAlliance: [],
            blueAlliance: [],
            accentAlliance: .neutral
        )
    }

    private func breakSubtitle(after previousLabel: String) -> String {
        if let number = extractTrailingMatchNumber(from: previousLabel) {
            return "After match \(number)"
        }
        return "After \(previousLabel)"
    }

    private func extractTrailingMatchNumber(from label: String) -> String? {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ")
        guard let last = parts.last else { return nil }
        let allowed = CharacterSet(charactersIn: "0123456789-")
        let candidate = String(last).trimmingCharacters(in: .punctuationCharacters)
        guard !candidate.isEmpty,
              candidate.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            return nil
        }
        return candidate
    }

    private func resolveCurrentOnFieldLabel(matches: [NexusLiveMatch], nowMilliseconds: Int64) -> String? {
        let onFieldMatches = matches.filter { $0.status.lowercased().contains("on field") }
        if let resolved = mostRelevantCurrentMatchLabel(from: onFieldMatches, nowMilliseconds: nowMilliseconds) {
            return resolved
        }

        let onDeckMatches = matches.filter { $0.status.lowercased().contains("on deck") }
        if let resolved = mostRelevantCurrentMatchLabel(from: onDeckMatches, nowMilliseconds: nowMilliseconds) {
            return resolved
        }

        return nil
    }

    private func mostRelevantCurrentMatchLabel(from matches: [NexusLiveMatch], nowMilliseconds: Int64) -> String? {
        let dated = matches.compactMap { match -> (String, Int64)? in
            let t = match.times.estimatedOnFieldTimeMillis
                ?? match.times.estimatedStartTimeMillis
                ?? match.times.estimatedOnDeckTimeMillis
            guard let t else { return nil }
            return (match.label, t)
        }
        guard !dated.isEmpty else { return nil }

        let pastOrNow = dated.filter { $0.1 <= nowMilliseconds }.sorted { $0.1 > $1.1 }
        if let latestPast = pastOrNow.first {
            return latestPast.0
        }
        return dated.sorted { $0.1 < $1.1 }.first?.0
    }

    private func statusPriority(_ status: String) -> Int {
        let s = status.lowercased()
        if s.contains("on field") { return 0 }
        if s.contains("on deck") { return 1 }
        if s.contains("now queuing") { return 2 }
        if s.contains("queuing soon") { return 3 }
        return 4
    }

    private func parseTeamNumbers(from raw: [String: Any], key: String) -> [String] {
        if let strings = raw[key] as? [String] {
            return strings.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        if let ints = raw[key] as? [Int] {
            return ints.map(String.init)
        }
        if let numbers = raw[key] as? [NSNumber] {
            return numbers.map(\.stringValue)
        }
        return []
    }

    private func int64Value(_ value: Any?) -> Int64? {
        if let value = value as? Int64 { return value }
        if let value = value as? Int { return Int64(value) }
        if let value = value as? Double { return Int64(value) }
        if let value = value as? String, let parsed = Int64(value) { return parsed }
        return nil
    }

    private func formatMillisToTime(_ milliseconds: Int64?) -> String? {
        guard let milliseconds, milliseconds > 0 else { return nil }
        let date = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000.0)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private struct NexusLiveEventPayload {
        let latestMatchLabel: String?
        let eventName: String?
        let matches: [NexusLiveMatch]
        let announcements: [NexusFeedItem]
        let partsRequests: [NexusFeedItem]
    }

    private struct NexusLiveMatch {
        let label: String
        let status: String
        let breakAfter: String?
        let redTeams: [String]
        let blueTeams: [String]
        let times: NexusLiveMatchTimes
    }

    private struct NexusLiveMatchTimes {
        let estimatedQueueTimeMillis: Int64?
        let estimatedOnDeckTimeMillis: Int64?
        let estimatedOnFieldTimeMillis: Int64?
        let estimatedStartTimeMillis: Int64?
    }

    private func debugLog(_ message: String) {
#if DEBUG
        print("[NexusAPIClient] \(message)")
#endif
    }
}

/// Nexus `match.status` değerleri — https://frc.nexus/api/v1/docs
enum NexusQueueStatus {
    static let queuingSoon = "Queuing soon"
    static let nowQueuing = "Now queuing"
    static let onDeck = "On deck"
    static let onField = "On field"

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
