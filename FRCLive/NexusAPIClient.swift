import Foundation

enum NexusQueuingStatus: String, Decodable {
    case notCalled = "Not Called"
    case calledToQueue = "Called to Queue"
    case onField = "On Field"
    case unknown = "Unknown"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self)) ?? ""
        switch raw.lowercased() {
        case "not called":
            self = .notCalled
        case "called to queue", "called":
            self = .calledToQueue
        case "on field":
            self = .onField
        default:
            self = .unknown
        }
    }
}

struct NexusTeamQueueSnapshot {
    let currentMatchOnField: String
    let teamNextMatch: String?
    let estimatedStartTime: String?
    let queuingStatus: NexusQueuingStatus
}

struct NexusUpcomingQueueItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let estimatedQueueTime: String?
    let scheduledStartTime: String?
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
    let status: NexusQueuingStatus

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

        let primaryStatus = try container.decodeIfPresent(NexusQueuingStatus.self, forKey: .queueStatus)
        let fallbackStatus = try container.decodeIfPresent(NexusQueuingStatus.self, forKey: .status)
        status = primaryStatus ?? fallbackStatus ?? .unknown
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
                queuingStatus: .calledToQueue
            )
        }

        let (data, _, resolvedEventCode) = try await fetchQueuingPayload(eventCode: eventCode)
        debugLog("Queue status=200 event=\(resolvedEventCode) team=\(teamNumber)")
        let liveEvent = try parseLiveEventPayload(data: data)
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let currentOnField = resolveCurrentOnFieldLabel(matches: liveEvent.matches, nowMilliseconds: nowMs)
        let current = currentOnField ?? liveEvent.latestMatchLabel ?? "-"

        guard let teamMatch = prioritizedMatch(for: teamNumber, matches: liveEvent.matches) else {
            return NexusTeamQueueSnapshot(
                currentMatchOnField: current,
                teamNextMatch: nil,
                estimatedStartTime: nil,
                queuingStatus: .unknown
            )
        }

        return NexusTeamQueueSnapshot(
            currentMatchOnField: current,
            teamNextMatch: teamMatch.label,
            estimatedStartTime: formatMillisToTime(teamMatch.times.estimatedStartTimeMillis),
            queuingStatus: mapStatusToQueueStatus(teamMatch.status)
        )
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
        let upcomingMatches = liveEvent.matches.filter { isUpcomingMatch($0, nowMilliseconds: nowMs) }
        let minimumPhaseRank = phaseRank(from: liveEvent.latestMatchLabel ?? "")
        let phaseFilteredMatches = upcomingMatches.filter { match in
            let rank = phaseRank(from: match.label)
            if minimumPhaseRank == 0 { return true }
            return rank >= minimumPhaseRank
        }
        let teamNumberString = String(teamNumber)
        let teamOnlyMatches = phaseFilteredMatches.filter { match in
            let includesTeam = match.redTeams.contains(teamNumberString) || match.blueTeams.contains(teamNumberString)
            return includesTeam || isBreakMatch(match)
        }

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
                redAlliance: match.redTeams,
                blueAlliance: match.blueTeams,
                accentAlliance: accent
            ))
            previousMatch = match
        }

        return NexusQueuingBoardSnapshot(
            divisionName: liveEvent.eventName,
            currentMatchOnField: liveEvent.latestMatchLabel ?? "-",
            entries: parsedEntries
        )
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

        return NexusLiveEventPayload(
            latestMatchLabel: latestMatchLabel,
            eventName: eventName,
            matches: matches
        )
    }

    private func parseLiveMatch(raw: [String: Any]) -> NexusLiveMatch? {
        guard let label = raw["label"] as? String, !label.isEmpty else {
            return nil
        }
        let status = (raw["status"] as? String) ?? "Unknown"
        let redTeams = (raw["redTeams"] as? [String]) ?? []
        let blueTeams = (raw["blueTeams"] as? [String]) ?? []
        let timesRaw = raw["times"] as? [String: Any] ?? [:]

        return NexusLiveMatch(
            label: label,
            status: status,
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

    private func prioritizedMatch(for teamNumber: Int, matches: [NexusLiveMatch]) -> NexusLiveMatch? {
        let key = String(teamNumber)
        let teamMatches = matches.filter { $0.redTeams.contains(key) || $0.blueTeams.contains(key) }
        guard !teamMatches.isEmpty else { return nil }
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let upcomingTeamMatches = teamMatches.filter { isUpcomingMatch($0, nowMilliseconds: nowMs) }
        let source = upcomingTeamMatches.isEmpty ? teamMatches : upcomingTeamMatches

        // Prefer the nearest active match first, then by estimated queue/start times.
        return source.sorted { lhs, rhs in
            let lhsRank = statusPriority(lhs.status)
            let rhsRank = statusPriority(rhs.status)
            if lhsRank != rhsRank { return lhsRank < rhsRank }

            let lhsTime = lhs.times.estimatedQueueTimeMillis ?? lhs.times.estimatedStartTimeMillis ?? Int64.max
            let rhsTime = rhs.times.estimatedQueueTimeMillis ?? rhs.times.estimatedStartTimeMillis ?? Int64.max
            return lhsTime < rhsTime
        }.first
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
        if normalized.contains("qualification") || normalized.contains("qual") || normalized.contains("qm") {
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
            subtitle: "After \(previous.label)",
            estimatedQueueTime: nil,
            scheduledStartTime: nextStartText,
            redAlliance: [],
            blueAlliance: [],
            accentAlliance: .neutral
        )
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

    private func mapStatusToQueueStatus(_ status: String) -> NexusQueuingStatus {
        let s = status.lowercased()
        if s.contains("on field") { return .onField }
        if s.contains("on deck") || s.contains("now queuing") {
            return .calledToQueue
        }
        if s.contains("queuing soon") {
            return .notCalled
        }
        return .unknown
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
    }

    private struct NexusLiveMatch {
        let label: String
        let status: String
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
