import Foundation
import Security

struct TBATeamProfile: Decodable {
    let nickname: String?
}

struct TBASimpleAlliance: Decodable {
    let teamKeys: [String]
    let score: Int?

    enum CodingKeys: String, CodingKey {
        case teamKeys = "team_keys"
        case score
    }

    init(teamKeys: [String], score: Int? = nil) {
        self.teamKeys = teamKeys
        self.score = score
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

private struct TBAEventTeamSimple: Decodable {
    let key: String
    let nickname: String?
    let name: String?
}

struct TBAAwardRecipient: Decodable {
    let teamKey: String?
    let teamNumber: Int?
    let awardee: String?

    enum CodingKeys: String, CodingKey {
        case teamKey = "team_key"
        case teamNumber = "team_number"
        case awardee
    }

    init(teamKey: String?, teamNumber: Int? = nil, awardee: String? = nil) {
        self.teamKey = teamKey
        self.teamNumber = teamNumber
        self.awardee = awardee
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

/// TBA tarihleri `yyyy-MM-dd` string olarak gelir. Bunları UTC gece yarısı `Date` ile parse edip
/// yerel `startOfDay` ile kıyaslamak, son gün ve saat dilimi kaynaklı “tamamlandı” tutarsızlıklarına yol açar.
enum TBAEventCalendar {
    /// Verilen günü kullanıcının yerel takviminde o günün başlangıcına sabitler (öğlen anchor ile DST güvenli).
    static func startOfLocalCalendarDay(fromYyyyMmDd string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let parts = trimmed.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var dc = DateComponents()
        dc.calendar = Calendar.current
        dc.timeZone = TimeZone.current
        dc.year = parts[0]
        dc.month = parts[1]
        dc.day = parts[2]
        dc.hour = 12
        dc.minute = 0
        dc.second = 0
        guard let anchor = Calendar.current.date(from: dc) else { return nil }
        return Calendar.current.startOfDay(for: anchor)
    }

    /// Bugünün yerel takvim günü, bitiş gününden **sonra** ise etkinlik tarihsel olarak bitmiştır.
    /// (Bitiş gününün kendisi hâlâ “devam ediyor” kabul edilir.)
    static func isPastEndLocalCalendarDay(endYyyyMmDd: String, now: Date = Date()) -> Bool {
        guard let endDayStart = startOfLocalCalendarDay(fromYyyyMmDd: endYyyyMmDd) else { return false }
        let todayStart = Calendar.current.startOfDay(for: now)
        return Calendar.current.compare(todayStart, to: endDayStart, toGranularity: .day) == .orderedDescending
    }

    /// Onboarding’de saklanan bitiş tarihi; boşsa `false` (başlangıç tarihine düşmeyiz — çok günlü etkinliklerde yanlış “tamamlandı” olur).
    static func isStoredEventPastEnd(endYyyyMmDd: String, now: Date = Date()) -> Bool {
        let trimmed = endYyyyMmDd.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return isPastEndLocalCalendarDay(endYyyyMmDd: trimmed, now: now)
    }
}

final class TBAAPIClient {
    static let shared = TBAAPIClient()
    static let tbaAuthKeyStorageKey = "tbaAuthKey"
    private let demoTeamNumber = "99999"

    private var tbaAuthKey: String {
        let secureValue = SecureStore.read(key: Self.tbaAuthKeyStorageKey)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !secureValue.isEmpty {
            return secureValue
        }

        // One-time migration from plain UserDefaults to Keychain.
        let legacyValue = (UserDefaults.standard.string(forKey: Self.tbaAuthKeyStorageKey) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !legacyValue.isEmpty {
            SecureStore.write(key: Self.tbaAuthKeyStorageKey, value: legacyValue)
            UserDefaults.standard.removeObject(forKey: Self.tbaAuthKeyStorageKey)
            debugLog("Migrated TBA key from UserDefaults to Keychain.")
            return legacyValue
        }

        return ""
    }

    private init() {}

    func persistedTBAAuthKey() -> String {
        tbaAuthKey
    }

    func saveTBAAuthKey(_ value: String) {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        SecureStore.write(key: Self.tbaAuthKeyStorageKey, value: cleaned)
        // Cleanup legacy location if it exists.
        UserDefaults.standard.removeObject(forKey: Self.tbaAuthKeyStorageKey)
    }

    func clearTBAAuthKey() {
        SecureStore.delete(key: Self.tbaAuthKeyStorageKey)
        UserDefaults.standard.removeObject(forKey: Self.tbaAuthKeyStorageKey)
    }

    func validateTBAAuthKey(_ value: String) async throws {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw TBAAPIClientError.unauthorized
        }
        // /status endpoint returns 200 without auth. Use a protected endpoint instead.
        guard let url = URL(string: "https://www.thebluealliance.com/api/v3/team/frc1") else {
            throw TBAAPIClientError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue(cleaned, forHTTPHeaderField: "X-TBA-Auth-Key")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TBAAPIClientError.failedToLoadEvents
        }

        switch httpResponse.statusCode {
        case 200:
            return
        case 401, 403:
            throw TBAAPIClientError.unauthorized
        default:
            throw TBAAPIClientError.failedToLoadEvents
        }
    }

    /// TBA `/team/frc{n}/media/{year}` — avatar (base64 veya URL) döner; yoksa nil.
    func fetchTeamAvatarURL(teamNumber: String) async throws -> URL? {
        if teamNumber == demoTeamNumber {
            return nil
        }

        let cleanedKey = tbaAuthKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedKey.isEmpty else {
            throw TBAAPIClientError.unauthorized
        }

        for year in mediaYearsToTry() {
            if let url = try await fetchTeamAvatarURL(teamNumber: teamNumber, year: year, authKey: cleanedKey) {
                return url
            }
        }
        return nil
    }

    func clearCachedTeamAvatar(teamNumber: String) {
        let file = cachedAvatarFileURL(teamNumber: teamNumber)
        try? FileManager.default.removeItem(at: file)
    }

    private func mediaYearsToTry() -> [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(Set([currentYear, 2026, 2025])).sorted(by: >)
    }

    private func fetchTeamAvatarURL(teamNumber: String, year: Int, authKey: String) async throws -> URL? {
        guard let url = URL(string: "https://www.thebluealliance.com/api/v3/team/frc\(teamNumber)/media/\(year)") else {
            throw TBAAPIClientError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue(authKey, forHTTPHeaderField: "X-TBA-Auth-Key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TBAAPIClientError.failedToLoadEvents
        }
        debugLog("Team media status=\(httpResponse.statusCode) team=\(teamNumber) year=\(year)")

        switch httpResponse.statusCode {
        case 200:
            guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return nil
            }
            return parseTeamAvatarURL(from: json, teamNumber: teamNumber)
        case 401, 403:
            throw TBAAPIClientError.unauthorized
        case 404:
            return nil
        default:
            throw TBAAPIClientError.failedToLoadEvents
        }
    }

    private func parseTeamAvatarURL(from items: [[String: Any]], teamNumber: String) -> URL? {
        if let avatar = items.first(where: { ($0["type"] as? String)?.lowercased() == "avatar" }),
           let url = avatarMediaURL(from: avatar, teamNumber: teamNumber) {
            return url
        }

        for item in items {
            let mediaType = (item["type"] as? String)?.lowercased() ?? ""
            if mediaType == "avatar", let url = avatarMediaURL(from: item, teamNumber: teamNumber) {
                return url
            }
        }

        for item in items {
            if let url = avatarMediaURL(from: item, teamNumber: teamNumber) {
                return url
            }
        }
        return nil
    }

    private func avatarMediaURL(from item: [String: Any], teamNumber: String) -> URL? {
        let details = item["details"] as? [String: Any]

        if let base64 = details?["base64Image"] as? String,
           let cached = writeCachedAvatarPNG(teamNumber: teamNumber, base64: base64) {
            return cached
        }

        if let imageURL = details?["image_url"] as? String,
           let url = absoluteMediaURL(imageURL) {
            return url
        }

        if let localURL = details?["local_image_url"] as? String,
           let url = absoluteMediaURL(localURL) {
            return url
        }

        for key in ["url", "avatar_url"] {
            if let raw = details?[key] as? String, let url = absoluteMediaURL(raw) {
                return url
            }
        }

        if let viewURL = item["view_url"] as? String, let url = absoluteMediaURL(viewURL) {
            return url
        }

        return nil
    }

    private func absoluteMediaURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        if trimmed.hasPrefix("//") {
            return URL(string: "https:\(trimmed)")
        }
        if trimmed.hasPrefix("/") {
            return URL(string: "https://www.thebluealliance.com\(trimmed)")
        }
        return URL(string: trimmed)
    }

    private func cachedAvatarFileURL(teamNumber: String) -> URL {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("frclive-avatar-\(teamNumber).png")
    }

    private func writeCachedAvatarPNG(teamNumber: String, base64: String) -> URL? {
        let cleaned = base64
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
        guard let data = Data(base64Encoded: cleaned), !data.isEmpty else { return nil }

        let fileURL = cachedAvatarFileURL(teamNumber: teamNumber)
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            debugLog("Avatar cache write failed team=\(teamNumber): \(error.localizedDescription)")
            return nil
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
        debugLog("Team profile status=\(httpResponse.statusCode) team=\(teamNumber)")

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
                TBAEvent(name: "Demo Active Regional", eventCode: "demoactive", eventKey: "2026demoactive", startDate: today, endDate: today, city: "Istanbul"),
                TBAEvent(name: "Demo Marmara Regional", eventCode: "trmr", eventKey: "2026trmr", startDate: "2026-03-20", endDate: "2026-03-22", city: "Istanbul"),
                TBAEvent(name: "Demo Bosphorus Regional", eventCode: "trbo", eventKey: "2026trbo", startDate: "2026-03-27", endDate: "2026-03-29", city: "Istanbul"),
                TBAEvent(name: "Demo Championship", eventCode: "cmp", eventKey: "2026cmp", startDate: "2026-04-18", endDate: "2026-04-20", city: "Houston")
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
        debugLog("Team events status=\(httpResponse.statusCode) team=\(teamNumber)")

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
        debugLog("Event matches status=\(httpResponse.statusCode) event=\(eventKey)")

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
        debugLog("Event rankings status=\(httpResponse.statusCode) event=\(eventKey)")

        switch httpResponse.statusCode {
        case 200:
            do {
                let decoded = try JSONDecoder().decode(TBARankingsResponse.self, from: data)
                let teamNameMap = (try? await fetchEventTeamNames(eventKey: eventKey, authKey: cleanedKey)) ?? [:]
                return decoded.rankings.map { ranking in
                    let resolvedName = teamNameMap[ranking.teamKey] ?? ranking.teamName
                    return TBARankingEntry(
                        rank: ranking.rank,
                        teamKey: ranking.teamKey,
                        teamName: resolvedName,
                        record: ranking.record
                    )
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
        debugLog("Event awards status=\(httpResponse.statusCode) event=\(eventKey)")

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

    func fetchEventTeamNameMap(eventCode: String) async throws -> [String: String] {
        let eventKey = normalizedEventKey(from: eventCode)

        if (UserDefaults.standard.string(forKey: "teamNumber") ?? "") == demoTeamNumber {
            return [
                "frc99999": "Demo Robotics",
                "frc6459": "AG Robotik",
                "frc6415": "Anatolian Eagles",
                "frc4784": "Bosphorus Bots"
            ]
        }

        let cleanedKey = tbaAuthKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedKey.isEmpty else {
            throw TBAAPIClientError.unauthorized
        }

        return try await fetchEventTeamNames(eventKey: eventKey, authKey: cleanedKey)
    }

    private func demoMatches(for eventCode: String) -> [TBASimpleMatch] {
        let demoMatches: [TBASimpleMatch] = [
            TBASimpleMatch(
                key: "\(eventCode)_pm1",
                compLevel: "pm",
                matchNumber: 1,
                setNumber: 1,
                alliances: TBASimpleAlliances(
                    red: TBASimpleAlliance(teamKeys: ["frc99999", "frc6415", "frc8154"], score: 92),
                    blue: TBASimpleAlliance(teamKeys: ["frc6459", "frc4784", "frc8840"], score: 88)
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
                    red: TBASimpleAlliance(teamKeys: ["frc99999", "frc6415", "frc8154"], score: 110),
                    blue: TBASimpleAlliance(teamKeys: ["frc6459", "frc4784", "frc8840"], score: 97)
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
                    red: TBASimpleAlliance(teamKeys: ["frc99999", "frc7285", "frc7748"], score: 84),
                    blue: TBASimpleAlliance(teamKeys: ["frc10213", "frc2234", "frc5980"], score: 101)
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
                    red: TBASimpleAlliance(teamKeys: ["frc6459", "frc5234", "frc4134"], score: 76),
                    blue: TBASimpleAlliance(teamKeys: ["frc99999", "frc8840", "frc3310"], score: 73)
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
                    red: TBASimpleAlliance(teamKeys: ["frc99999", "frc7285", "frc7748"], score: 126),
                    blue: TBASimpleAlliance(teamKeys: ["frc6459", "frc5234", "frc4134"], score: 121)
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

    private func fetchEventTeamNames(eventKey: String, authKey: String) async throws -> [String: String] {
        guard let url = URL(string: "https://www.thebluealliance.com/api/v3/event/\(eventKey)/teams/simple") else {
            throw TBAAPIClientError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue(authKey, forHTTPHeaderField: "X-TBA-Auth-Key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TBAAPIClientError.failedToLoadEvents
        }
        debugLog("Event teams(simple) status=\(httpResponse.statusCode) event=\(eventKey)")

        let teams = try JSONDecoder().decode([TBAEventTeamSimple].self, from: data)
        return Dictionary(
            uniqueKeysWithValues: teams.map { team in
                let resolvedName = (team.nickname?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? team.nickname : team.name) ?? team.key.replacingOccurrences(of: "frc", with: "")
                return (team.key, resolvedName)
            }
        )
    }

    private func debugLog(_ message: String) {
#if DEBUG
        print("[TBAAPIClient] \(message)")
#endif
    }
}

private enum SecureStore {
    static func read(key: String) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        return value
    }

    static func write(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let attributes: [String: Any] = [kSecValueData as String: data]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var createQuery = query
            createQuery[kSecValueData as String] = data
            SecItemAdd(createQuery as CFDictionary, nil)
        }
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
