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
        request.setValue(cleaned, forHTTPHeaderField: "X-API-Key")
        request.setValue(cleaned, forHTTPHeaderField: "x-api-key")
        request.setValue(cleaned, forHTTPHeaderField: "Nexus-Api-Key")
        request.setValue("Bearer \(cleaned)", forHTTPHeaderField: "Authorization")

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
        let current = liveEvent.latestMatchLabel ?? "-"

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
                        subtitle: "~16:48 gibi sıraya alınacak",
                        estimatedQueueTime: "16:48",
                        scheduledStartTime: "17:12",
                        redAlliance: ["10396", "245", "9072"],
                        blueAlliance: ["836", "9483", "1306"],
                        accentAlliance: .blue
                    ),
                    NexusUpcomingQueueItem(
                        id: "demo-2",
                        title: "Sıralama 24",
                        subtitle: "~18:40 gibi sıraya alınacak",
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
                        subtitle: "~21:49 gibi sıraya alınacak",
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
        let parsedEntries = liveEvent.matches.enumerated().map { index, match in
            let teamNumberString = String(teamNumber)
            let accent: NexusAllianceAccent
            if match.redTeams.contains(teamNumberString) {
                accent = .red
            } else if match.blueTeams.contains(teamNumberString) {
                accent = .blue
            } else {
                accent = .neutral
            }

            let queueTimeText = formatMillisToTime(match.times.estimatedQueueTimeMillis)
            let subtitle: String?
            if let queueTimeText {
                subtitle = "~\(queueTimeText) gibi sıraya alınacak"
            } else {
                subtitle = nil
            }

            return NexusUpcomingQueueItem(
                id: "\(match.label)-\(index)",
                title: match.label,
                subtitle: subtitle,
                estimatedQueueTime: queueTimeText,
                scheduledStartTime: formatMillisToTime(match.times.estimatedStartTimeMillis),
                redAlliance: match.redTeams,
                blueAlliance: match.blueTeams,
                accentAlliance: accent
            )
        }

        return NexusQueuingBoardSnapshot(
            divisionName: liveEvent.eventName,
            currentMatchOnField: liveEvent.latestMatchLabel ?? "-",
            entries: parsedEntries
        )
    }

    private func fetchQueuingPayload(eventCode: String) async throws -> (Data, HTTPURLResponse, String) {
        let normalizedCandidates = candidateEventCodes(from: eventCode)
        var lastStatusCode: Int?

        for candidate in normalizedCandidates {
            guard let url = URL(string: "https://frc.nexus/api/v1/event/\(candidate)") else {
                continue
            }

            var request = URLRequest(url: url)
            let apiKey = nexusApiKey
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue(apiKey, forHTTPHeaderField: "Nexus-Api-Key")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

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
                throw NexusAPIClientError.unauthorized
            }
        }

        switch lastStatusCode {
        case 404:
            throw NexusAPIClientError.eventNotFound
        case 502, 503, 504:
            throw NexusAPIClientError.serviceUnavailable
        default:
            throw NexusAPIClientError.invalidResponse
        }
    }

    private func candidateEventCodes(from eventCode: String) -> [String] {
        var candidates: [String] = []
        let trimmed = eventCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            candidates.append(trimmed)
        }

        if trimmed.count > 4 {
            let dropYear = String(trimmed.dropFirst(4))
            if !dropYear.isEmpty {
                candidates.append(dropYear)
            }
        }

        return Array(NSOrderedSet(array: candidates)) as? [String] ?? candidates
    }

    private func parseLiveEventPayload(data: Data) throws -> NexusLiveEventPayload {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NexusAPIClientError.invalidResponse
        }

        let latestMatchLabel = json["latestMatchLabel"] as? String
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

        // Prefer the nearest active match first, then by estimated queue/start times.
        return teamMatches.sorted { lhs, rhs in
            let lhsRank = statusPriority(lhs.status)
            let rhsRank = statusPriority(rhs.status)
            if lhsRank != rhsRank { return lhsRank < rhsRank }

            let lhsTime = lhs.times.estimatedQueueTimeMillis ?? lhs.times.estimatedStartTimeMillis ?? Int64.max
            let rhsTime = rhs.times.estimatedQueueTimeMillis ?? rhs.times.estimatedStartTimeMillis ?? Int64.max
            return lhsTime < rhsTime
        }.first
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
