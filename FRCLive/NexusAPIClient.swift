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

    var errorDescription: String? {
        switch self {
        case .invalidRequest, .invalidResponse:
            return "Canlı veri alınamadı."
        case .teamNotFoundInQueue:
            return "Sıradaki maç bulunamadı."
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

        guard let url = URL(string: "https://frc.nexus/api/v1/events/\(eventCode)/queuing") else {
            throw NexusAPIClientError.invalidRequest
        }

        var request = URLRequest(url: url)
        let apiKey = nexusApiKey
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let httpResponse = response as? HTTPURLResponse {
                debugLog("Queue status=\(httpResponse.statusCode) event=\(eventCode) team=\(teamNumber)")
            }
            throw NexusAPIClientError.invalidResponse
        }
        debugLog("Queue status=\(httpResponse.statusCode) event=\(eventCode) team=\(teamNumber)")

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

    private func debugLog(_ message: String) {
#if DEBUG
        print("[NexusAPIClient] \(message)")
#endif
    }
}
