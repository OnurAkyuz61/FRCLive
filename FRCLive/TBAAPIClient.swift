import Foundation

final class TBAAPIClient {
    static let shared = TBAAPIClient()

    private init() {}

    func fetchTeamEvents2026(teamNumber: String) async throws -> [TBAEvent] {
        try await FRCService.shared.fetchTeamEvents2026(teamNumber: teamNumber)
    }
}
