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

        let decoded = try JSONDecoder().decode(NexusQueuingResponse.self, from: data)
        let current = decoded.currentMatchOnField ?? "-"
        guard let teamEntry = decoded.entries.first(where: { $0.teamNumber == teamNumber }) else {
            return NexusTeamQueueSnapshot(
                currentMatchOnField: current,
                teamNextMatch: nil,
                estimatedStartTime: nil,
                queuingStatus: .unknown
            )
        }

        return NexusTeamQueueSnapshot(
            currentMatchOnField: current,
            teamNextMatch: teamEntry.nextMatch,
            estimatedStartTime: teamEntry.estimatedStartTime,
            queuingStatus: teamEntry.status
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

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json else {
            throw NexusAPIClientError.invalidResponse
        }

        let currentOnField = (json["current_match_on_field"] as? String)
            ?? (json["current_match"] as? String)
            ?? "-"
        let division = (json["division_name"] as? String)
            ?? (json["division"] as? String)
            ?? (json["name"] as? String)

        let rawEntries = (json["entries"] as? [[String: Any]])
            ?? (json["queue"] as? [[String: Any]])
            ?? []
        let parsedEntries = rawEntries.enumerated().map { index, raw in
            parseUpcomingItem(raw: raw, index: index, teamNumber: teamNumber)
        }

        return NexusQueuingBoardSnapshot(
            divisionName: division,
            currentMatchOnField: currentOnField,
            entries: parsedEntries
        )
    }

    private func fetchQueuingPayload(eventCode: String) async throws -> (Data, HTTPURLResponse, String) {
        let normalizedCandidates = candidateEventCodes(from: eventCode)
        var lastStatusCode: Int?

        for candidate in normalizedCandidates {
            guard let url = URL(string: "https://frc.nexus/api/v1/events/\(candidate)/queuing") else {
                continue
            }

            var request = URLRequest(url: url)
            let apiKey = nexusApiKey
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
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

    private func parseUpcomingItem(raw: [String: Any], index: Int, teamNumber: Int) -> NexusUpcomingQueueItem {
        let matchLabel = stringValue(raw, keys: ["match_label", "match", "next_match", "team_next_match", "title"]) ?? "Match -"
        let queueText = stringValue(raw, keys: ["queue_text", "subtitle", "note", "status_text", "queue_status_text"])
        let estimatedQueue = stringValue(raw, keys: ["estimated_queue_time", "estimated_time", "estimated_start_time"])
        let scheduledStart = stringValue(raw, keys: ["scheduled_start_time", "start_time", "match_time"])

        let red = teamList(raw: raw, keys: ["red_alliance", "red", "red_teams", "redAlliance"])
        let blue = teamList(raw: raw, keys: ["blue_alliance", "blue", "blue_teams", "blueAlliance"])

        let teamNumberString = String(teamNumber)
        let accent: NexusAllianceAccent
        if red.contains(teamNumberString) {
            accent = .red
        } else if blue.contains(teamNumberString) {
            accent = .blue
        } else if !red.isEmpty || !blue.isEmpty {
            accent = .neutral
        } else if matchLabel.lowercased().contains("lunch") || matchLabel.lowercased().contains("ara") {
            accent = .neutral
        } else {
            accent = .blue
        }

        let subtitle = queueText ?? estimatedQueue.map { "~\($0) gibi sıraya alınacak" }
        let id = stringValue(raw, keys: ["id", "key"]) ?? "\(matchLabel)-\(index)"

        return NexusUpcomingQueueItem(
            id: id,
            title: matchLabel,
            subtitle: subtitle,
            estimatedQueueTime: estimatedQueue,
            scheduledStartTime: scheduledStart,
            redAlliance: red,
            blueAlliance: blue,
            accentAlliance: accent
        )
    }

    private func stringValue(_ raw: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = raw[key] as? String, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
            if let value = raw[key] as? Int {
                return String(value)
            }
        }
        return nil
    }

    private func teamList(raw: [String: Any], keys: [String]) -> [String] {
        for key in keys {
            if let items = raw[key] as? [String] {
                return items.map { $0.replacingOccurrences(of: "frc", with: "") }
            }
            if let items = raw[key] as? [Int] {
                return items.map(String.init)
            }
            if let itemGroups = raw[key] as? [[String: Any]] {
                let resolved = itemGroups.compactMap { item -> String? in
                    if let team = item["team_number"] as? Int { return String(team) }
                    if let team = item["team"] as? Int { return String(team) }
                    if let team = item["team_number"] as? String { return team.replacingOccurrences(of: "frc", with: "") }
                    return nil
                }
                if !resolved.isEmpty {
                    return resolved
                }
            }
        }
        return []
    }

    private func debugLog(_ message: String) {
#if DEBUG
        print("[NexusAPIClient] \(message)")
#endif
    }
}
