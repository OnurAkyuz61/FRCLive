import Foundation

final class TBAAPIClient {
    static let shared = TBAAPIClient()
    var tbaAuthKey = ""

    private init() {}

    func fetchTeamEvents2026(teamNumber: String) async -> [TBAEvent] {
        let cleanedKey = tbaAuthKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedKey.isEmpty else {
            return mockEvents
        }

        guard let url = URL(string: "https://www.thebluealliance.com/api/v3/team/frc\(teamNumber)/events/2026") else {
            return mockEvents
        }

        var request = URLRequest(url: url)
        request.setValue(cleanedKey, forHTTPHeaderField: "X-TBA-Auth-Key")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return mockEvents
            }

            let decoded = try JSONDecoder().decode([TBAEvent].self, from: data)
            return decoded.isEmpty ? mockEvents : decoded
        } catch {
            return mockEvents
        }
    }

    private var mockEvents: [TBAEvent] {
        [
            TBAEvent(
                name: "Istanbul Regional",
                eventCode: "2026istr",
                date: "2026-03-05",
                city: "Istanbul"
            ),
            TBAEvent(
                name: "Marmara Regional",
                eventCode: "2026marm",
                date: "2026-03-15",
                city: "Istanbul"
            ),
            TBAEvent(
                name: "FIRST Championship",
                eventCode: "2026cmp",
                date: "2026-04-15",
                city: "Houston"
            )
        ]
    }
}
