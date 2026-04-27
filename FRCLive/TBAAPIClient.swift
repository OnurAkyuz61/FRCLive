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
    static let tbaAuthKeyStorageKey = "tbaAuthKey"

    private var tbaAuthKey: String {
        let value = UserDefaults.standard.string(forKey: Self.tbaAuthKeyStorageKey) ?? ""
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private init() {}

    func fetchTeamAvatarURL(teamNumber: String) async throws -> URL? {
        let cleanedKey = tbaAuthKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedKey.isEmpty else {
            throw TBAAPIClientError.unauthorized
        }

        guard let url = URL(string: "https://www.thebluealliance.com/api/v3/team/frc\(teamNumber)/media/2026") else {
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
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            else {
                return nil
            }

            for item in json {
                let mediaType = (item["type"] as? String)?.lowercased() ?? ""
                let details = item["details"] as? [String: Any]
                let directURL = details?["url"] as? String
                let imageURL = details?["image_url"] as? String
                let avatarURL = details?["avatar_url"] as? String

                if let candidate = directURL ?? imageURL ?? avatarURL, let url = URL(string: candidate) {
                    if mediaType.contains("avatar") || mediaType.contains("png") || mediaType.contains("imgur") {
                        return url
                    }
                }
            }
            return nil
        case 401, 403:
            throw TBAAPIClientError.unauthorized
        case 404:
            throw TBAAPIClientError.invalidTeam
        default:
            throw TBAAPIClientError.failedToLoadEvents
        }
    }

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
