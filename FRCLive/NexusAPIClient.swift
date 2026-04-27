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
        currentMatchOnField = try container.decodeIfPresent(String.self, forKey: .currentMatchOnField)
            ?? container.decodeIfPresent(String.self, forKey: .currentMatch)
        entries =
            (try container.decodeIfPresent([NexusQueueEntry].self, forKey: .entries))
            ?? (try container.decodeIfPresent([NexusQueueEntry].self, forKey: .queue))
            ?? []
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
        teamNumber =
            (try container.decodeIfPresent(Int.self, forKey: .teamNumber))
            ?? (try container.decode(Int.self, forKey: .team))
        nextMatch =
            (try container.decodeIfPresent(String.self, forKey: .nextMatch))
            ?? (try container.decodeIfPresent(String.self, forKey: .nextMatchAlt))
        estimatedStartTime =
            (try container.decodeIfPresent(String.self, forKey: .estimatedStartTime))
            ?? (try container.decodeIfPresent(String.self, forKey: .estimatedTimeAlt))
        status =
            (try container.decodeIfPresent(NexusQueuingStatus.self, forKey: .queueStatus))
            ?? (try container.decodeIfPresent(NexusQueuingStatus.self, forKey: .status))
            ?? .unknown
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
    private init() {}

    func fetchQueueSnapshot(eventCode: String, teamNumber: Int) async throws -> NexusTeamQueueSnapshot {
        guard let url = URL(string: "https://frc.nexus/api/v1/events/\(eventCode)/queuing") else {
            throw NexusAPIClientError.invalidRequest
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NexusAPIClientError.invalidResponse
        }

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
}
