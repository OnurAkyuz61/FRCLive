import SwiftUI

struct AnnouncementsView: View {
    @EnvironmentObject private var announcementStore: AnnouncementStore
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("selectedEventCode") private var selectedEventCode: String = ""
    @AppStorage("selectedEventName") private var selectedEventName: String = ""
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue

    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .tr }
    private var processBlue: Color { Color(red: 0 / 255, green: 156 / 255, blue: 215 / 255) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                if announcementStore.isLoading && announcementStore.announcements.isEmpty {
                    loadingState
                } else if let error = announcementStore.errorMessage, announcementStore.announcements.isEmpty {
                    errorState(error)
                } else if announcementStore.announcements.isEmpty {
                    emptyState
                } else {
                    announcementsList
                }
            }
            .navigationTitle(L10n.text(.announcements, language: appLanguage))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.text(.eventSelection, language: appLanguage)) {
                        selectedEventCode = ""
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if announcementStore.unreadCount > 0 {
                        Button(L10n.text(.markAllRead, language: appLanguage)) {
                            announcementStore.markAllRead()
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .refreshable {
                await announcementStore.refresh(
                    eventCode: selectedEventCode,
                    teamNumber: teamNumber,
                    language: appLanguage,
                    notify: false
                )
            }
            .task {
                await announcementStore.refresh(
                    eventCode: selectedEventCode,
                    teamNumber: teamNumber,
                    language: appLanguage,
                    notify: false
                )
            }
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 30_000_000_000)
                    await announcementStore.refresh(
                        eventCode: selectedEventCode,
                        teamNumber: teamNumber,
                        language: appLanguage,
                        notify: true
                    )
                }
            }
        }
    }

    private var announcementsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if !selectedEventName.isEmpty {
                    Text(selectedEventName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                }

                LazyVStack(spacing: 10) {
                    ForEach(announcementStore.announcements) { item in
                        NavigationLink {
                            AnnouncementDetailView(
                                item: item,
                                eventName: selectedEventName
                            )
                        } label: {
                            FeedItemRowView(
                                item: item,
                                isRead: announcementStore.isRead(item.id),
                                language: appLanguage,
                                processBlue: processBlue
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 88)
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text(L10n.text(.loadingAnnouncements, language: appLanguage))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.title2)
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(L10n.text(.retry, language: appLanguage)) {
                Task {
                    await announcementStore.refresh(
                        eventCode: selectedEventCode,
                        teamNumber: teamNumber,
                        language: appLanguage,
                        notify: false
                    )
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "megaphone")
                .font(.system(size: 36))
                .foregroundColor(processBlue.opacity(0.85))
            Text(L10n.text(.noAnnouncements, language: appLanguage))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
}

private struct FeedItemRowView: View {
    let item: NexusFeedItem
    let isRead: Bool
    let language: AppLanguage
    let processBlue: Color

    private var accent: Color { item.accentColor(processBlue: processBlue) }
    private var iconName: String { item.iconName() }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(isRead ? 0.12 : 0.22))
                    .frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .font(.body.weight(.semibold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Spacer(minLength: 8)
                    Text(AnnouncementFormatters.listTime(item.postedDate, language: language))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(item.message)
                    .font(.subheadline)
                    .foregroundColor(isRead ? .secondary : .primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                Text(item.categoryLabel(language: language))
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(accent))
            }

            if !isRead {
                Circle()
                    .fill(accent)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.secondary.opacity(0.55))
                    .padding(.top, 8)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isRead ? Color.black.opacity(0.06) : accent.opacity(0.28), lineWidth: 1)
                )
        )
    }
}

struct AnnouncementDetailView: View {
    @EnvironmentObject private var announcementStore: AnnouncementStore
    let item: NexusFeedItem
    let eventName: String

    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .tr }
    private var processBlue: Color { Color(red: 0 / 255, green: 156 / 255, blue: 215 / 255) }

    private var accent: Color { item.accentColor(processBlue: processBlue) }
    private var detailTitle: String { item.detailTitle(language: appLanguage) }
    private var iconName: String { item.iconName() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(accent))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(detailTitle)
                            .font(.headline)
                        Text(AnnouncementFormatters.fullDateTime(item.postedDate, language: appLanguage))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

                if !eventName.isEmpty {
                    Text(eventName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(processBlue)
                }

                Text(item.categoryLabel(language: appLanguage))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(accent))

                Text(item.message)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(detailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            announcementStore.markRead(item.id)
        }
    }
}

enum AnnouncementFormatters {
    static func listTime(_ date: Date, language: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .en ? "en_US_POSIX" : "tr_TR")
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDateInYesterday(date) {
            return language == .en ? "Yesterday" : "Dün"
        } else {
            formatter.dateFormat = "d MMM HH:mm"
        }
        return formatter.string(from: date)
    }

    static func fullDateTime(_ date: Date, language: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .en ? "en_US_POSIX" : "tr_TR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
