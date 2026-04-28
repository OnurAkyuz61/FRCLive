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
    @State private var eventPhase: EventPhase = .unknown
    @State private var pulse = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard

                    Text(selectedEventName.isEmpty ? L10n.text(.eventNotSelected, language: appLanguage) : selectedEventName)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)

                    eventPhaseRow

                    liveMatchCard
                    currentFieldStatusRow
                    dataSourceRow
                    liveActivityStatus

                    if let liveErrorMessage {
                        Text(liveErrorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
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
                pushWidgetSnapshot()
                await startLivePolling()
            }
        }
    }

    private var headerCard: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(L10n.text(.teamPrefix, language: appLanguage)) \(teamNumber)")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.primary)
                Text(teamNickname.isEmpty ? "Overcharge" : teamNickname)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            TeamAvatarView(avatarURLString: teamAvatarURL, size: 46)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var liveMatchCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.text(.nextMatch, language: appLanguage))
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
            }

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
                        .font(.system(size: 34, weight: .bold, design: .rounded))
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
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.black.opacity(0.10), Color.black.opacity(0.03)],
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
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var eventPhaseRow: some View {
        HStack(spacing: 8) {
            Image(systemName: eventPhase.iconName)
                .foregroundColor(eventPhase.iconColor)
            Text("\(L10n.text(.eventPhase, language: appLanguage)): \(eventPhase.localizedText(language: appLanguage))")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
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
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var dataSourceRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(dataSourceColor)
                .frame(width: 10, height: 10)
            Text("\(L10n.text(.dataSource, language: appLanguage)): \(dataSourceText)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
        .padding(.top, 6)
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
            await refreshEventPhase(using: snapshot)
            liveSnapshot = snapshot
            liveErrorMessage = nil
            isMatchScheduleNotCreated = false
            await handleLiveIntegrations(with: snapshot)
        } catch {
            do {
                let allMatches = try await TBAAPIClient.shared.fetchEventMatches(eventCode: selectedEventCode)
                eventPhase = resolveEventPhase(matches: allMatches, snapshot: nil)
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
                eventPhase = .unknown
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
        let eventName = selectedEventName.isEmpty ? L10n.text(.eventNotSelected, language: appLanguage) : selectedEventName

        if liveActivitiesEnabled {
            await LiveActivityManager.shared.update(
                teamNumber: teamNumber,
                eventName: eventName,
                nextMatch: nextMatch,
                status: status,
                currentOnField: snapshot.currentMatchOnField,
                estimatedStart: estimated,
                languageCode: appLanguageRaw
            )
        } else {
            await LiveActivityManager.shared.end()
        }

        // Keep widget in sync on every live snapshot, independent from notification settings.
        pushWidgetSnapshot(
            nextMatch: nextMatch,
            queueStatus: status
        )

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

    private func pushWidgetSnapshot(nextMatch: String? = nil, queueStatus: String? = nil) {
        let updatedAt = appLanguage == .tr ? "Az önce" : "Just now"

        WidgetDataStore.writeSnapshot(
            teamNumber: teamNumber.isEmpty ? "----" : teamNumber,
            eventName: selectedEventName.isEmpty ? L10n.text(.eventNotSelected, language: appLanguage) : selectedEventName,
            nextMatch: nextMatch ?? (liveSnapshot?.teamNextMatch ?? "-"),
            queueStatus: queueStatus ?? (liveSnapshot.map { statusText($0.queuingStatus) } ?? L10n.text(.queueStatusNotCalled, language: appLanguage)),
            updatedAt: updatedAt,
            languageCode: appLanguageRaw
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

    private var dataSourceText: String {
        if teamNumber == "99999" {
            return L10n.text(.dataSourceDemo, language: appLanguage)
        }
        if liveErrorMessage != nil {
            return L10n.text(.dataSourceOffline, language: appLanguage)
        }
        return L10n.text(.dataSourceLive, language: appLanguage)
    }

    private var dataSourceColor: Color {
        if teamNumber == "99999" {
            return .orange
        }
        if liveErrorMessage != nil {
            return .red
        }
        return .green
    }

    @MainActor
    private func refreshEventPhase(using snapshot: NexusTeamQueueSnapshot?) async {
        guard !selectedEventCode.isEmpty else {
            eventPhase = .unknown
            return
        }
        do {
            let matches = try await TBAAPIClient.shared.fetchEventMatches(eventCode: selectedEventCode)
            eventPhase = resolveEventPhase(matches: matches, snapshot: snapshot)
        } catch {
            eventPhase = resolveEventPhase(matches: [], snapshot: snapshot)
        }
    }

    private func resolveEventPhase(matches: [TBASimpleMatch], snapshot: NexusTeamQueueSnapshot?) -> EventPhase {
        if let snapshot {
            let lowerCombined = "\(snapshot.currentMatchOnField) \(snapshot.teamNextMatch ?? "")".lowercased()
            if lowerCombined.contains("qf") || lowerCombined.contains("sf") || lowerCombined.contains("final") {
                return .playoff
            }
            if lowerCombined.contains("qual") || lowerCombined.contains("qm") {
                return .qualification
            }
            if lowerCombined.contains("practice") || lowerCombined.contains("pm") || lowerCombined.contains("pr") {
                return .practice
            }
        }

        let now = Int(Date().timeIntervalSince1970)
        let playoffLevels = Set(["ef", "qf", "sf", "f"])
        let qualificationLevels = Set(["qm"])
        let practiceLevels = Set(["pm", "pr"])

        let playoffStarted = matches.contains { match in
            guard playoffLevels.contains(match.compLevel) else { return false }
            if let start = match.predictedTime ?? match.time {
                return start <= now
            }
            return true
        }
        if playoffStarted { return .playoff }

        let qualificationStarted = matches.contains { match in
            guard qualificationLevels.contains(match.compLevel) else { return false }
            if let start = match.predictedTime ?? match.time {
                return start <= now
            }
            return true
        }
        if qualificationStarted { return .qualification }

        let practiceStarted = matches.contains { match in
            guard practiceLevels.contains(match.compLevel) else { return false }
            if let start = match.predictedTime ?? match.time {
                return start <= now
            }
            return true
        }
        if practiceStarted { return .practice }

        if matches.contains(where: { playoffLevels.contains($0.compLevel) || qualificationLevels.contains($0.compLevel) }) {
            return .practice
        }
        return .unknown
    }
}

private enum EventPhase {
    case practice
    case qualification
    case playoff
    case unknown

    var iconName: String {
        switch self {
        case .practice: return "wrench.and.screwdriver"
        case .qualification: return "flag"
        case .playoff: return "flag.checkered"
        case .unknown: return "questionmark.circle"
        }
    }

    var iconColor: Color {
        switch self {
        case .practice: return .orange
        case .qualification: return .blue
        case .playoff: return .green
        case .unknown: return .secondary
        }
    }

    func localizedText(language: AppLanguage) -> String {
        switch self {
        case .practice:
            return L10n.text(.eventPhasePractice, language: language)
        case .qualification:
            return L10n.text(.eventPhaseQualification, language: language)
        case .playoff:
            return L10n.text(.eventPhasePlayoff, language: language)
        case .unknown:
            return L10n.text(.eventPhaseUnknown, language: language)
        }
    }
}

#Preview {
    DashboardView()
}
