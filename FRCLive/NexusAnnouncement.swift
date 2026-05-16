import Foundation

struct NexusAnnouncement: Identifiable, Hashable, Codable {
    let id: String
    let message: String
    let postedTimeMillis: Int64

    var postedDate: Date {
        Date(timeIntervalSince1970: TimeInterval(postedTimeMillis) / 1000.0)
    }
}
