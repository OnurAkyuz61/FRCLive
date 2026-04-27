import SwiftUI
import UserNotifications

struct DashboardView: View {
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("selectedEventName") private var selectedEventName: String = ""
    @AppStorage("teamNickname") private var teamNickname: String = ""
    @AppStorage("teamAvatarURL") private var teamAvatarURL: String = ""
    @AppStorage("selectedEventCode") private var selectedEventCode: String = ""
    @AppStorage("liveActivitiesEnabled") private var liveActivitiesEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("lastQueueAlertKey") private var lastQueueAlertKey: String = ""
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .tr }
    @State private var liveSnapshot: NexusTeamQueueSnapshot?
    @State private var isLoadingLiveData = false
    @State private var liveErrorMessage: String?
    @State private var isMatchScheduleNotCreated = false
    @State private var pulse = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(L10n.text(.teamPrefix, language: appLanguage)) \(teamNumber)")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.black)
                            Text(teamNickname.isEmpty ? "Overcharge" : teamNickname)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        TeamAvatarView(avatarURLString: teamAvatarURL, size: 42)
                    }

                    Text(selectedEventName.isEmpty ? L10n.text(.eventNotSelected, language: appLanguage) : selectedEventName)
                        .font(.headline)
                        .foregroundColor(.secondary)

                    liveMatchCard
                    currentFieldStatusRow
                    liveActivityStatus

                    if let liveErrorMessage {
                        Text(liveErrorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }

                    footer
                }
                .padding(20)
                .padding(.bottom, 88)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(L10n.text(.dashboard, language: appLanguage))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.text(.eventSelection, language: appLanguage)) {
                        selectedEventCode = ""
                    }
                }
            }
            .task {
                await startLivePolling()
            }
        }
    }

    private var liveMatchCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.text(.nextMatch, language: appLanguage))
                .font(.headline)
                .foregroundColor(.black)

            if isLoadingLiveData && liveSnapshot == nil {
                HStack {
                    ProgressView()
                    Text(L10n.text(.loadingEvents, language: appLanguage))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if let snapshot = liveSnapshot, let nextMatch = snapshot.teamNextMatch, !nextMatch.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(nextMatch)
                        .font(.title.weight(.bold))
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor(snapshot.queuingStatus))
                            .frame(width: 10, height: 10)
                            .scaleEffect(pulse ? 1.15 : 0.85)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
                        Text(statusText(snapshot.queuingStatus))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                    }

                    Text("\(L10n.text(.estimatedStart, language: appLanguage)): \(snapshot.estimatedStartTime ?? "-")")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text(
                        isMatchScheduleNotCreated
                        ? L10n.text(.matchScheduleNotCreated, language: appLanguage)
                        : L10n.text(.noUpcomingMatch, language: appLanguage)
                    )
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.black.opacity(0.12), Color.black.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear { pulse = true }
    }

    private var currentFieldStatusRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .foregroundColor(.blue)
            Text("\(L10n.text(.currentlyOnField, language: appLanguage)) \(liveSnapshot?.currentMatchOnField ?? "-")")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var liveActivityStatus: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
            Text(L10n.text(.liveActivityReady, language: appLanguage))
                .font(.subheadline.weight(.medium))
                .foregroundColor(.black)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var footer: some View {
        HStack {
            Spacer()
            Link(L10n.text(.poweredBy, language: appLanguage), destination: URL(string: "https://onurakyuz.com")!)
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.top, 8)
    }

    @MainActor
    private func startLivePolling() async {
        while !Task.isCancelled {
            await fetchLiveDataOnce()
            do {
                try await Task.sleep(nanoseconds: 30_000_000_000)
            } catch {
                break
            }
        }
    }

    @MainActor
    private func fetchLiveDataOnce() async {
        guard let team = Int(teamNumber), !selectedEventCode.isEmpty else { return }
        isLoadingLiveData = true
        defer { isLoadingLiveData = false }

        do {
            let snapshot = try await NexusAPIClient.shared.fetchQueueSnapshot(
                eventCode: selectedEventCode,
                teamNumber: team
            )
            liveSnapshot = snapshot
            liveErrorMessage = nil
            isMatchScheduleNotCreated = false
            await handleLiveIntegrations(with: snapshot)
        } catch {
            do {
                let allMatches = try await TBAAPIClient.shared.fetchEventMatches(eventCode: selectedEventCode)
                let teamKey = "frc\(team)"
                let teamMatches = allMatches.filter { match in
                    match.alliances.red.teamKeys.contains(teamKey) || match.alliances.blue.teamKeys.contains(teamKey)
                }

                if allMatches.isEmpty || teamMatches.isEmpty {
                    isMatchScheduleNotCreated = true
                    liveErrorMessage = nil
                    liveSnapshot = nil
                } else {
                    isMatchScheduleNotCreated = false
                    liveErrorMessage = L10n.text(.liveDataError, language: appLanguage)
                }
            } catch {
                isMatchScheduleNotCreated = false
                liveErrorMessage = L10n.text(.liveDataError, language: appLanguage)
            }
        }
    }

    @MainActor
    private func handleLiveIntegrations(with snapshot: NexusTeamQueueSnapshot) async {
        let nextMatch = snapshot.teamNextMatch ?? L10n.text(.noUpcomingMatch, language: appLanguage)
        let status = statusText(snapshot.queuingStatus)
        let estimated = snapshot.estimatedStartTime ?? "-"

        if liveActivitiesEnabled {
            await LiveActivityManager.shared.update(
                teamNumber: teamNumber,
                eventName: selectedEventName,
                nextMatch: nextMatch,
                status: status,
                currentOnField: snapshot.currentMatchOnField,
                estimatedStart: estimated
            )
        } else {
            await LiveActivityManager.shared.end()
        }

        guard notificationsEnabled else { return }
        guard snapshot.queuingStatus == .calledToQueue || snapshot.queuingStatus == .onField else { return }

        let alertKey = "\(selectedEventCode)|\(nextMatch)|\(snapshot.queuingStatus.rawValue)"
        guard alertKey != lastQueueAlertKey else { return }
        lastQueueAlertKey = alertKey

        AppNotificationManager.shared.sendQueueStatusNotification(
            teamNumber: teamNumber,
            nextMatch: nextMatch,
            statusText: status
        )
    }

    private func statusText(_ status: NexusQueuingStatus) -> String {
        switch status {
        case .notCalled:
            return L10n.text(.queueStatusNotCalled, language: appLanguage)
        case .calledToQueue:
            return L10n.text(.queueStatusCalled, language: appLanguage)
        case .onField:
            return L10n.text(.queueStatusOnField, language: appLanguage)
        case .unknown:
            return L10n.text(.queueStatusUnknown, language: appLanguage)
        }
    }

    private func statusColor(_ status: NexusQueuingStatus) -> Color {
        switch status {
        case .notCalled:
            return .gray
        case .calledToQueue:
            return .orange
        case .onField:
            return .green
        case .unknown:
            return .secondary
        }
    }
}

#Preview {
    DashboardView()
}
