import Foundation

struct TBATeamProfile: Decodable {
    let nickname: String?
}

struct TBASimpleAlliance: Decodable {
    let teamKeys: [String]

    enum CodingKeys: String, CodingKey {
        case teamKeys = "team_keys"
    }
}

struct TBASimpleAlliances: Decodable {
    let red: TBASimpleAlliance
    let blue: TBASimpleAlliance
}

struct TBASimpleMatch: Decodable, Identifiable {
    var id: String { key }

    let key: String
    let compLevel: String
    let matchNumber: Int
    let setNumber: Int
    let alliances: TBASimpleAlliances
    let time: Int?
    let predictedTime: Int?

    enum CodingKeys: String, CodingKey {
        case key
        case compLevel = "comp_level"
        case matchNumber = "match_number"
        case setNumber = "set_number"
        case alliances
        case time
        case predictedTime = "predicted_time"
    }
}

struct TBARankingRecord: Decodable {
    let wins: Int
    let losses: Int
    let ties: Int
}

struct TBARankingEntry: Decodable, Identifiable {
    var id: String { teamKey }

    let rank: Int
    let teamKey: String
    let teamName: String
    let record: TBARankingRecord

    enum CodingKeys: String, CodingKey {
        case rank
        case teamKey = "team_key"
        case nickname
        case record
    }

    init(rank: Int, teamKey: String, teamName: String, record: TBARankingRecord) {
        self.rank = rank
        self.teamKey = teamKey
        self.teamName = teamName
        self.record = record
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rank = try container.decode(Int.self, forKey: .rank)
        teamKey = try container.decode(String.self, forKey: .teamKey)
        teamName = try container.decodeIfPresent(String.self, forKey: .nickname) ?? teamKey.replacingOccurrences(of: "frc", with: "")
        record = try container.decode(TBARankingRecord.self, forKey: .record)
    }
}

private struct TBARankingsResponse: Decodable {
    let rankings: [TBARankingEntry]
}

struct TBAAwardRecipient: Decodable {
    let teamKey: String?

    enum CodingKeys: String, CodingKey {
        case teamKey = "team_key"
    }

    init(teamKey: String?) {
        self.teamKey = teamKey
    }
}

struct TBAAward: Decodable, Identifiable {
    var id: String { "\(name)-\(awardType)" }

    let name: String
    let awardType: Int
    let eventKey: String?
    let recipients: [TBAAwardRecipient]

    enum CodingKeys: String, CodingKey {
        case name
        case awardType = "award_type"
        case eventKey = "event_key"
        case recipientList = "recipient_list"
    }

    init(name: String, awardType: Int, eventKey: String?, recipients: [TBAAwardRecipient]) {
        self.name = name
        self.awardType = awardType
        self.eventKey = eventKey
        self.recipients = recipients
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        awardType = try container.decodeIfPresent(Int.self, forKey: .awardType) ?? -1
        eventKey = try container.decodeIfPresent(String.self, forKey: .eventKey)
        recipients = try container.decodeIfPresent([TBAAwardRecipient].self, forKey: .recipientList) ?? []
    }
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
    private let demoTeamNumber = "99999"

    private var tbaAuthKey: String {
        let value = UserDefaults.standard.string(forKey: Self.tbaAuthKeyStorageKey) ?? ""
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private init() {}

    func fetchTeamAvatarURL(teamNumber: String) async throws -> URL? {
        if teamNumber == demoTeamNumber {
            return nil
        }

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
        if teamNumber == demoTeamNumber {
            return TBATeamProfile(nickname: "Demo Robotics")
        }

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
        if teamNumber == demoTeamNumber {
            let today = Self.demoDateFormatter.string(from: Date())
            return [
                TBAEvent(name: "Demo Active Regional", eventCode: "demoactive", eventKey: "2026demoactive", date: today, city: "Istanbul"),
                TBAEvent(name: "Demo Marmara Regional", eventCode: "trmr", eventKey: "2026trmr", date: "2026-03-20", city: "Istanbul"),
                TBAEvent(name: "Demo Bosphorus Regional", eventCode: "trbo", eventKey: "2026trbo", date: "2026-03-27", city: "Istanbul"),
                TBAEvent(name: "Demo Championship", eventCode: "cmp", eventKey: "2026cmp", date: "2026-04-18", city: "Houston")
            ]
        }

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

    func fetchEventMatches(eventCode: String) async throws -> [TBASimpleMatch] {
        let eventKey = normalizedEventKey(from: eventCode)
        if (UserDefaults.standard.string(forKey: "teamNumber") ?? "") == demoTeamNumber {
            return demoMatches(for: eventKey)
        }

        let cleanedKey = tbaAuthKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedKey.isEmpty else {
            throw TBAAPIClientError.unauthorized
        }

        guard let url = URL(string: "https://www.thebluealliance.com/api/v3/event/\(eventKey)/matches/simple") else {
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
                let matches = try JSONDecoder().decode([TBASimpleMatch].self, from: data)
                return matches.sorted {
                    let lhsTime = $0.predictedTime ?? $0.time ?? Int.max
                    let rhsTime = $1.predictedTime ?? $1.time ?? Int.max
                    if lhsTime != rhsTime { return lhsTime < rhsTime }
                    if $0.compLevel != $1.compLevel { return $0.compLevel < $1.compLevel }
                    return $0.matchNumber < $1.matchNumber
                }
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

    func fetchEventRankings(eventCode: String) async throws -> [TBARankingEntry] {
        let eventKey = normalizedEventKey(from: eventCode)
        if (UserDefaults.standard.string(forKey: "teamNumber") ?? "") == demoTeamNumber {
            return demoRankings()
        }

        let cleanedKey = tbaAuthKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedKey.isEmpty else {
            throw TBAAPIClientError.unauthorized
        }

        guard let url = URL(string: "https://www.thebluealliance.com/api/v3/event/\(eventKey)/rankings") else {
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
                let decoded = try JSONDecoder().decode(TBARankingsResponse.self, from: data)
                return decoded.rankings
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

    func fetchEventAwards(eventCode: String) async throws -> [TBAAward] {
        let eventKey = normalizedEventKey(from: eventCode)
        if (UserDefaults.standard.string(forKey: "teamNumber") ?? "") == demoTeamNumber {
            return [
                TBAAward(
                    name: "Regional Winner",
                    awardType: 0,
                    eventKey: eventKey,
                    recipients: [
                        TBAAwardRecipient(teamKey: "frc99999"),
                        TBAAwardRecipient(teamKey: "frc6459")
                    ]
                ),
                TBAAward(
                    name: "Industrial Design Award",
                    awardType: 9,
                    eventKey: eventKey,
                    recipients: [TBAAwardRecipient(teamKey: "frc6459")]
                )
            ]
        }

        let cleanedKey = tbaAuthKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedKey.isEmpty else {
            throw TBAAPIClientError.unauthorized
        }

        guard let url = URL(string: "https://www.thebluealliance.com/api/v3/event/\(eventKey)/awards") else {
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
                return try JSONDecoder().decode([TBAAward].self, from: data)
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

    private func demoMatches(for eventCode: String) -> [TBASimpleMatch] {
        let demoMatches: [TBASimpleMatch] = [
            TBASimpleMatch(
                key: "\(eventCode)_pm1",
                compLevel: "pm",
                matchNumber: 1,
                setNumber: 1,
                alliances: TBASimpleAlliances(
                    red: TBASimpleAlliance(teamKeys: ["frc99999", "frc6415", "frc8154"]),
                    blue: TBASimpleAlliance(teamKeys: ["frc6459", "frc4784", "frc8840"])
                ),
                time: 1_773_590_000,
                predictedTime: 1_773_590_000
            ),
            TBASimpleMatch(
                key: "\(eventCode)_qm1",
                compLevel: "qm",
                matchNumber: 1,
                setNumber: 1,
                alliances: TBASimpleAlliances(
                    red: TBASimpleAlliance(teamKeys: ["frc99999", "frc6415", "frc8154"]),
                    blue: TBASimpleAlliance(teamKeys: ["frc6459", "frc4784", "frc8840"])
                ),
                time: 1_773_600_000,
                predictedTime: 1_773_600_000
            ),
            TBASimpleMatch(
                key: "\(eventCode)_qm12",
                compLevel: "qm",
                matchNumber: 12,
                setNumber: 1,
                alliances: TBASimpleAlliances(
                    red: TBASimpleAlliance(teamKeys: ["frc99999", "frc7285", "frc7748"]),
                    blue: TBASimpleAlliance(teamKeys: ["frc10213", "frc2234", "frc5980"])
                ),
                time: 1_773_601_200,
                predictedTime: 1_773_601_260
            ),
            TBASimpleMatch(
                key: "\(eventCode)_qm25",
                compLevel: "qm",
                matchNumber: 25,
                setNumber: 1,
                alliances: TBASimpleAlliances(
                    red: TBASimpleAlliance(teamKeys: ["frc6459", "frc5234", "frc4134"]),
                    blue: TBASimpleAlliance(teamKeys: ["frc99999", "frc8840", "frc3310"])
                ),
                time: 1_773_603_000,
                predictedTime: 1_773_603_200
            ),
            TBASimpleMatch(
                key: "\(eventCode)_qf1m1",
                compLevel: "qf",
                matchNumber: 1,
                setNumber: 1,
                alliances: TBASimpleAlliances(
                    red: TBASimpleAlliance(teamKeys: ["frc99999", "frc7285", "frc7748"]),
                    blue: TBASimpleAlliance(teamKeys: ["frc6459", "frc5234", "frc4134"])
                ),
                time: 1_773_610_000,
                predictedTime: 1_773_610_000
            )
        ]
        return demoMatches
    }

    private func demoRankings() -> [TBARankingEntry] {
        [
            TBARankingEntry(rank: 1, teamKey: "frc99999", teamName: "Demo Robotics", record: TBARankingRecord(wins: 11, losses: 1, ties: 0)),
            TBARankingEntry(rank: 2, teamKey: "frc6459", teamName: "AG Robotik", record: TBARankingRecord(wins: 9, losses: 3, ties: 0)),
            TBARankingEntry(rank: 3, teamKey: "frc6415", teamName: "Anatolian Eagles", record: TBARankingRecord(wins: 8, losses: 4, ties: 0)),
            TBARankingEntry(rank: 4, teamKey: "frc4784", teamName: "Bosphorus Bots", record: TBARankingRecord(wins: 8, losses: 4, ties: 0))
        ]
    }

    private static let demoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private func normalizedEventKey(from value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return trimmed }

        let hasYearPrefix = trimmed.count >= 4 && trimmed.prefix(4).allSatisfy(\.isNumber)
        if hasYearPrefix { return trimmed }
        return "2026\(trimmed)"
    }
}
