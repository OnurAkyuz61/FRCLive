import Combine
import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class AnnouncementStore: ObservableObject {
    static let shared = AnnouncementStore()

    @Published private(set) var announcements: [NexusFeedItem] = []
    @Published private(set) var unreadCount: Int = 0
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var readIDs: Set<String> = []
    private var knownIDs: Set<String> = []
    private var activeEventCode: String = ""
    private var didSeedKnownIDs = false

    private init() {}

    func refresh(
        eventCode: String,
        teamNumber: String,
        language: AppLanguage,
        notify: Bool
    ) async {
        let normalizedEvent = eventCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedEvent.isEmpty else {
            announcements = []
            unreadCount = 0
            errorMessage = nil
            return
        }

        if normalizedEvent != activeEventCode {
            activeEventCode = normalizedEvent
            loadPersistedState(for: normalizedEvent)
            didSeedKnownIDs = false
        }

        isLoading = announcements.isEmpty
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched = try await NexusAPIClient.shared.fetchEventFeed(
                eventCode: normalizedEvent,
                teamNumber: teamNumber
            )
            process(fetched, language: language, notify: notify)
        } catch {
            if announcements.isEmpty {
                errorMessage = L10n.text(.announcementsLoadError, language: language)
            }
        }
    }

    func markRead(_ id: String) {
        guard readIDs.insert(id).inserted else { return }
        persistReadIDs()
        recomputeUnread()
        objectWillChange.send()
    }

    func markAllRead() {
        readIDs.formUnion(announcements.map(\.id))
        persistReadIDs()
        recomputeUnread()
        setAppBadgeCount(0)
        objectWillChange.send()
    }

    func isRead(_ id: String) -> Bool {
        readIDs.contains(id)
    }

    private func process(_ items: [NexusFeedItem], language: AppLanguage, notify: Bool) {
        let sorted = items.sorted { $0.postedTimeMillis > $1.postedTimeMillis }
        announcements = sorted

        let currentIDs = Set(sorted.map(\.id))
        if !didSeedKnownIDs {
            knownIDs = currentIDs
            didSeedKnownIDs = true
            persistKnownIDs()
            recomputeUnread()
            return
        }

        let newIDs = currentIDs.subtracting(knownIDs)
        knownIDs = currentIDs
        persistKnownIDs()
        recomputeUnread()

        guard notify, UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }
        let teamNumber = UserDefaults.standard.string(forKey: "teamNumber") ?? ""
        for item in sorted where newIDs.contains(item.id) {
            AppNotificationManager.shared.sendFeedItemNotification(
                teamNumber: teamNumber,
                item: item,
                language: language
            )
        }
    }

    private func recomputeUnread() {
        unreadCount = announcements.filter { !readIDs.contains($0.id) }.count
        setAppBadgeCount(unreadCount)
    }

    private func setAppBadgeCount(_ count: Int) {
        Task {
            try? await UNUserNotificationCenter.current().setBadgeCount(count)
        }
    }

    private func loadPersistedState(for eventCode: String) {
        readIDs = Set(UserDefaults.standard.stringArray(forKey: readIDsKey(eventCode)) ?? [])
        knownIDs = Set(UserDefaults.standard.stringArray(forKey: knownIDsKey(eventCode)) ?? [])
        didSeedKnownIDs = !knownIDs.isEmpty
    }

    private func persistReadIDs() {
        guard !activeEventCode.isEmpty else { return }
        UserDefaults.standard.set(Array(readIDs), forKey: readIDsKey(activeEventCode))
    }

    private func persistKnownIDs() {
        guard !activeEventCode.isEmpty else { return }
        UserDefaults.standard.set(Array(knownIDs), forKey: knownIDsKey(activeEventCode))
    }

    private func readIDsKey(_ eventCode: String) -> String {
        "announcementReadIds_\(eventCode)"
    }

    private func knownIDsKey(_ eventCode: String) -> String {
        "announcementKnownIds_\(eventCode)"
    }

    func resetForLogout() {
        announcements = []
        unreadCount = 0
        readIDs = []
        knownIDs = []
        activeEventCode = ""
        didSeedKnownIDs = false
        errorMessage = nil
        setAppBadgeCount(0)
    }
}
