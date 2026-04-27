import Foundation

struct TBATeamProfile: Decodable {
    let nickname: String?
}

enum TBAAPIClientError: LocalizedError {
    case invalidRequest
    case unauthorized
    case invalidTeam
    case failedToLoadEvents

    var errorDescription: String? {
        switch self {
        case .invalidRequest, .failedToLoadEvents:
            return "Etkinlikler yüklenemedi veya geçersiz takım."
        case .unauthorized:
            return "TBA API anahtarı geçersiz."
        case .invalidTeam:
            return "Etkinlikler yüklenemedi veya geçersiz takım."
        }
    }
}

final class TBAAPIClient {
    static let shared = TBAAPIClient()
    var tbaAuthKey = "wYwgOi4y1OUsPNIaKEXyiBAFLlJcWiMDIte2W3mXa0QOwSzdswgzL6JLwSMSNaxn"

    private init() {}

    func fetchTeamProfile(teamNumber: String) async throws -> TBATeamProfile {
        let cleanedKey = tbaAuthKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedKey.isEmpty else {
            throw TBAAPIClientError.unauthorized
        }

        guard let url = URL(string: "https://www.thebluealliance.com/api/v3/team/frc\(teamNumber)") else {
            throw TBAAPIClientError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue(cleanedKey, forHTTPHeaderField: "X-TBA-Auth-Key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TBAAPIClientError.failedToLoadEvents
        }

        switch httpResponse.statusCode {
        case 200:
            do {
                return try JSONDecoder().decode(TBATeamProfile.self, from: data)
            } catch {
                throw TBAAPIClientError.failedToLoadEvents
            }
        case 401, 403:
            throw TBAAPIClientError.unauthorized
        case 404:
            throw TBAAPIClientError.invalidTeam
        default:
            throw TBAAPIClientError.failedToLoadEvents
        }
    }

    func fetchTeamEvents2026(teamNumber: String) async throws -> [TBAEvent] {
        let cleanedKey = tbaAuthKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedKey.isEmpty else {
            throw TBAAPIClientError.unauthorized
        }

        guard let url = URL(string: "https://www.thebluealliance.com/api/v3/team/frc\(teamNumber)/events/2026") else {
            throw TBAAPIClientError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue(cleanedKey, forHTTPHeaderField: "X-TBA-Auth-Key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TBAAPIClientError.failedToLoadEvents
        }

        switch httpResponse.statusCode {
        case 200:
            do {
                return try JSONDecoder().decode([TBAEvent].self, from: data)
            } catch {
                throw TBAAPIClientError.failedToLoadEvents
            }
        case 401, 403:
            throw TBAAPIClientError.unauthorized
        case 404:
            throw TBAAPIClientError.invalidTeam
        default:
            throw TBAAPIClientError.failedToLoadEvents
        }
    }
}
