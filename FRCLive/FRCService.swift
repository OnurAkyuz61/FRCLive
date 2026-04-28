import Foundation

struct TBAEvent: Decodable, Identifiable {
    var id: String { eventKey }

    let name: String
    let eventCode: String
    let eventKey: String
    let date: String
    let city: String?

    enum CodingKeys: String, CodingKey {
        case name
        case eventCode = "event_code"
        case eventKey = "key"
        case date
        case startDate = "start_date"
        case city
    }

    init(name: String, eventCode: String, eventKey: String, date: String, city: String?) {
        self.name = name
        self.eventCode = eventCode
        self.eventKey = eventKey
        self.date = date
        self.city = city
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        eventCode = try container.decode(String.self, forKey: .eventCode)
        eventKey = try container.decode(String.self, forKey: .eventKey)
        city = try container.decodeIfPresent(String.self, forKey: .city)

        if let explicitDate = try container.decodeIfPresent(String.self, forKey: .date) {
            date = explicitDate
        } else {
            date = try container.decode(String.self, forKey: .startDate)
        }
    }
}

struct NexusQueue: Decodable {
    let currentMatch: String
    let estimatedTime: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case currentMatch = "current_match"
        case estimatedTime = "estimated_time"
        case status
    }
}

enum FRCServiceError: LocalizedError, Equatable {
    case invalidResponse
    case invalidTeam
    case unauthorized
    case serverError
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Sunucudan beklenmeyen bir yanit alindi. Lutfen tekrar deneyin."
        case .invalidTeam:
            return "Girdiginiz takim numarasi TBA uzerinde bulunamadi."
        case .unauthorized:
            return "TBA API anahtari gecersiz veya eksik. X-TBA-Auth-Key degerini guncelleyin."
        case .serverError:
            return "Servis su anda kullanilamiyor. Biraz sonra tekrar deneyin."
        case .missingAPIKey:
            return "TBA API anahtari bulunamadi. Info.plist veya ortam degiskenine TBA_AUTH_KEY ekleyin."
        }
    }
}

final class FRCService {
    static let shared = FRCService()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private var tbaAuthKey: String? {
        if let infoValue = Bundle.main.object(forInfoDictionaryKey: "TBA_AUTH_KEY") as? String {
            let trimmed = infoValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        if let envValue = ProcessInfo.processInfo.environment["TBA_AUTH_KEY"] {
            let trimmed = envValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        return nil
    }

    func validateTeam(teamNumber: String) async throws {
        guard let tbaAuthKey else {
            throw FRCServiceError.missingAPIKey
        }

        guard let url = URL(string: "https://www.thebluealliance.com/api/v3/team/frc\(teamNumber)") else {
            throw FRCServiceError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.setValue(tbaAuthKey, forHTTPHeaderField: "X-TBA-Auth-Key")

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FRCServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return
        case 401, 403:
            throw FRCServiceError.unauthorized
        case 404:
            throw FRCServiceError.invalidTeam
        case 500...599:
            throw FRCServiceError.serverError
        default:
            throw FRCServiceError.invalidResponse
        }
    }

    func fetchTeamEvents2026(teamNumber: String) async throws -> [TBAEvent] {
        guard let tbaAuthKey else {
            throw FRCServiceError.missingAPIKey
        }

        guard let url = URL(string: "https://www.thebluealliance.com/api/v3/team/frc\(teamNumber)/events/2026") else {
            throw FRCServiceError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.setValue(tbaAuthKey, forHTTPHeaderField: "X-TBA-Auth-Key")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FRCServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401, 403:
            throw FRCServiceError.unauthorized
        case 404:
            throw FRCServiceError.invalidTeam
        case 500...599:
            throw FRCServiceError.serverError
        default:
            throw FRCServiceError.invalidResponse
        }

        do {
            return try JSONDecoder().decode([TBAEvent].self, from: data)
        } catch {
            throw FRCServiceError.invalidResponse
        }
    }

    func fetchLiveQueuingData(eventCode: String) async throws -> NexusQueue {
        guard let url = URL(string: "https://frc.nexus/api/v1/events/\(eventCode)/queuing") else {
            throw FRCServiceError.invalidResponse
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FRCServiceError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 500...599:
            throw FRCServiceError.serverError
        default:
            throw FRCServiceError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(NexusQueue.self, from: data)
        } catch {
            throw FRCServiceError.invalidResponse
        }
    }
}
