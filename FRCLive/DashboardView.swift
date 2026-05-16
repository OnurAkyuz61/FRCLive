import SwiftUI
import UserNotifications

struct DashboardView: View {
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("selectedEventName") private var selectedEventName: String = ""
    @AppStorage("selectedEventDate") private var selectedEventDate: String = ""
    @AppStorage("selectedEventEndDate") private var selectedEventEndDate: String = ""
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

                    if shouldTreatDashboardEventAsFinished {
                        completedEventBanner
                    }

                    eventPhaseRow

                    liveMatchCard
                    if !shouldTreatDashboardEventAsFinished {
                        currentFieldStatusRow
                    }
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
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !shouldTreatDashboardEventAsFinished {
                        NavigationLink {
                            UpcomingMatchesView()
                        } label: {
                            Image(systemName: "list.bullet.rectangle.portrait")
                                .foregroundColor(.primary)
                        }
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
            } else if !shouldTreatDashboardEventAsFinished,
                      let snapshot = liveSnapshot,
                      let nextMatch = snapshot.teamNextMatch,
                      !nextMatch.isEmpty {
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
                        shouldTreatDashboardEventAsFinished
                        ? L10n.text(.eventCompletedBanner, language: appLanguage)
                        : isMatchScheduleNotCreated
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

    private var completedEventBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.orange)
            Text(L10n.text(.eventCompletedBanner, language: appLanguage))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                )
        )
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

        let teamKey = "frc\(team)"
        await backfillSelectedEventEndDateIfNeeded()
        let allMatches = (try? await TBAAPIClient.shared.fetchEventMatches(eventCode: selectedEventCode)) ?? []

        if shouldTreatDashboardEventAsFinished {
            liveSnapshot = nil
            liveErrorMessage = nil
            isMatchScheduleNotCreated = false

            // Completed events should not keep live activities/alerts running from stale Nexus data.
            await LiveActivityManager.shared.end()
            pushWidgetSnapshot(
                nextMatch: L10n.text(.eventCompletedBanner, language: appLanguage),
                queueStatus: L10n.text(.queueStatusNotCalled, language: appLanguage)
            )

            eventPhase = resolveEventPhase(matches: allMatches, snapshot: nil)
            return
        }

        isLoadingLiveData = true
        defer { isLoadingLiveData = false }

        do {
            let snapshot = try await NexusAPIClient.shared.fetchQueueSnapshot(
                eventCode: selectedEventCode,
                teamNumber: team
            )
            await refreshEventPhase(using: snapshot, preloadedMatches: allMatches)
            liveSnapshot = snapshot
            liveErrorMessage = nil
            isMatchScheduleNotCreated = false
            await handleLiveIntegrations(with: snapshot)
            WidgetBackgroundRefreshManager.schedule()
            await AnnouncementStore.shared.refresh(
                eventCode: selectedEventCode,
                teamNumber: teamNumber,
                language: appLanguage,
                notify: true
            )
        } catch {
            eventPhase = resolveEventPhase(matches: allMatches, snapshot: nil)
            let teamMatches = filterTeamMatches(allMatches, teamKey: teamKey)

            if allMatches.isEmpty || teamMatches.isEmpty {
                isMatchScheduleNotCreated = true
                liveErrorMessage = nil
                liveSnapshot = nil
            } else {
                isMatchScheduleNotCreated = false
                liveErrorMessage = nexusErrorMessage(from: error)
                liveSnapshot = nil
            }
        }
    }

    private func filterTeamMatches(_ matches: [TBASimpleMatch], teamKey: String) -> [TBASimpleMatch] {
        matches.filter { match in
            match.alliances.red.teamKeys.contains(teamKey) || match.alliances.blue.teamKeys.contains(teamKey)
        }
    }

    @MainActor
    private func backfillSelectedEventEndDateIfNeeded() async {
        guard selectedEventEndDate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !selectedEventCode.isEmpty,
              !teamNumber.isEmpty,
              teamNumber != "99999" else { return }

        do {
            let events = try await TBAAPIClient.shared.fetchTeamEvents2026(teamNumber: teamNumber)
            let normalizedCode = selectedEventCode.lowercased()
            guard let event = events.first(where: {
                $0.eventCode.lowercased() == normalizedCode || $0.eventKey.lowercased() == normalizedCode
            }) else { return }

            selectedEventEndDate = event.endDate
            if selectedEventDate.isEmpty {
                selectedEventDate = event.startDate
            }
        } catch {
            // Bitiş tarihi olmadan devam et; etkinliği erken “tamamlandı” sayma.
        }
    }

    private var shouldTreatDashboardEventAsFinished: Bool {
        isSelectedEventCompleted
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
                statusCode: snapshot.queuingStatus.rawValue,
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
            nextMatch: nextMatch,
            statusText: status,
            language: appLanguage
        )
    }

    private func pushWidgetSnapshot(nextMatch: String? = nil, queueStatus: String? = nil) {
        let updatedAt = currentTimeLabel()

        let resolvedStatusCode = {
            if let queueStatus {
                return inferQueueStatusCode(from: queueStatus)
            }
            return liveSnapshot?.queuingStatus.rawValue ?? NexusQueuingStatus.unknown.rawValue
        }()

        WidgetDataStore.writeSnapshot(
            teamNumber: teamNumber.isEmpty ? "----" : teamNumber,
            teamName: teamNickname,
            eventName: selectedEventName.isEmpty ? L10n.text(.eventNotSelected, language: appLanguage) : selectedEventName,
            nextMatch: nextMatch ?? (liveSnapshot?.teamNextMatch ?? "-"),
            currentOnField: liveSnapshot?.currentMatchOnField ?? "-",
            queueStatus: queueStatus ?? (liveSnapshot.map { statusText($0.queuingStatus) } ?? L10n.text(.queueStatusNotCalled, language: appLanguage)),
            queueStatusCode: resolvedStatusCode,
            updatedAt: updatedAt,
            languageCode: appLanguageRaw
        )
    }

    private func inferQueueStatusCode(from queueStatus: String) -> String {
        let lower = queueStatus.lowercased()
        if lower.contains("not called") || lower.contains("henüz") || lower.contains("çağrılmadı") {
            return NexusQueuingStatus.notCalled.rawValue
        }
        if lower.contains("on field") || lower.contains("sahada") {
            return NexusQueuingStatus.onField.rawValue
        }
        if lower.contains("called") || (lower.contains("çağr") && !lower.contains("çağrılmadı")) {
            return NexusQueuingStatus.calledToQueue.rawValue
        }
        return NexusQueuingStatus.unknown.rawValue
    }

    private func currentTimeLabel() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: appLanguage == .tr ? "tr_TR" : "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
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

    private var isSelectedEventCompleted: Bool {
        TBAEventCalendar.isStoredEventPastEnd(endYyyyMmDd: selectedEventEndDate)
    }

    @MainActor
    private func refreshEventPhase(using snapshot: NexusTeamQueueSnapshot?, preloadedMatches: [TBASimpleMatch]? = nil) async {
        guard !selectedEventCode.isEmpty else {
            eventPhase = .unknown
            return
        }
        let matches: [TBASimpleMatch]
        if let preloadedMatches {
            matches = preloadedMatches
        } else {
            do {
                matches = try await TBAAPIClient.shared.fetchEventMatches(eventCode: selectedEventCode)
            } catch {
                matches = []
            }
        }
        eventPhase = resolveEventPhase(matches: matches, snapshot: snapshot)
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

    private func nexusErrorMessage(from error: Error) -> String {
        if let nexusError = error as? NexusAPIClientError {
            return nexusError.errorDescription ?? L10n.text(.liveDataError, language: appLanguage)
        }
        return L10n.text(.liveDataError, language: appLanguage)
    }
}

private extension DateFormatter {
    static let tbaEventDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
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

private struct UpcomingMatchesView: View {
    @AppStorage("selectedEventCode") private var selectedEventCode: String = ""
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("selectedEventDate") private var selectedEventDate: String = ""
    @AppStorage("selectedEventEndDate") private var selectedEventEndDate: String = ""
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue
    @AppStorage("selectedEventName") private var selectedEventName: String = ""
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .tr }

    @State private var board: NexusQueuingBoardSnapshot?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var expandedIDs: Set<String> = []

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            if isLoading && board == nil {
                VStack(spacing: 10) {
                    ProgressView()
                    Text(L10n.text(.loadingMatches, language: appLanguage))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    Button(L10n.text(.retry, language: appLanguage)) {
                        Task { await loadBoard() }
                    }
                }
                .padding(.horizontal, 24)
            } else if let board {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        headerCard(board: board)
                        if !board.currentMatchOnField.isEmpty, board.currentMatchOnField != "-" {
                            currentOnFieldCard(label: board.currentMatchOnField)
                        }
                        queueList(board: board)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .refreshable { await loadBoard() }
            }
        }
        .navigationTitle(L10n.text(.nextMatch, language: appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadBoard() }
    }

    private func headerCard(board: NexusQueuingBoardSnapshot) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text("✶")
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(L10n.text(.teamPrefix, language: appLanguage)) \(teamNumber)")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.primary)
                Text(board.divisionName ?? selectedEventName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func currentOnFieldCard(label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .foregroundColor(.blue)
            Text("\(L10n.text(.currentlyOnField, language: appLanguage)) \(label)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.blue.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func queueList(board: NexusQueuingBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(appLanguage == .tr ? "Yaklaşan maçlar" : "Upcoming matches")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))

            if board.entries.isEmpty {
                Text(appLanguage == .tr ? "Yaklaşan maç bulunamadı" : "No upcoming matches")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.systemBackground))
            }

            ForEach(board.entries) { item in
                VStack(spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedIDs.contains(item.id) {
                                expandedIDs.remove(item.id)
                            } else {
                                expandedIDs.insert(item.id)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(localizedBreakTitle(item.title))
                                .font(.title3.weight(.medium))
                                .foregroundColor(.white)
                            Spacer()
                            if let subtitle = localizedQueueSubtitle(for: item) {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.96))
                                    .lineLimit(1)
                            }
                            Image(systemName: expandedIDs.contains(item.id) ? "chevron.up" : "chevron.down")
                                .foregroundColor(.white.opacity(0.96))
                                .font(.footnote.weight(.semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(rowBackground(for: item))
                    }
                    .buttonStyle(.plain)

                    if expandedIDs.contains(item.id) {
                        details(item: item)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .overlay(
                    Rectangle()
                        .fill(Color.black.opacity(0.10))
                        .frame(height: 0.5),
                    alignment: .bottom
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
    }

    private func details(item: NexusUpcomingQueueItem) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            if isBreakLabel(item.title) {
                if let subtitle = localizedQueueSubtitle(for: item) {
                    Text("• \(subtitle)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.97))
                }
                if let resume = item.resumeMatchNumber {
                    let timeText = item.scheduledStartTime ?? "-"
                    let line = appLanguage == .tr
                        ? "• Sıraya alınma Sıralama \(resume) ile birlikte saat ~\(timeText) gibi devam edecek."
                        : "• Queuing will continue with Match \(resume) at around ~\(timeText)."
                    Text(line)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.97))
                }
            }

            if let estimatedQueueTime = item.estimatedQueueTime {
                Label(
                    appLanguage == .tr
                    ? "Tahmini sıraya alınma zamanı @ \(estimatedQueueTime)"
                    : "Estimated queue call @ \(estimatedQueueTime)",
                    systemImage: "clock"
                )
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.97))
            }

            if let scheduledStartTime = item.scheduledStartTime {
                Label(
                    appLanguage == .tr
                    ? "\(scheduledStartTime) saatinde başlaması planlandı"
                    : "Planned to start at \(scheduledStartTime)",
                    systemImage: "calendar"
                )
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.97))
            }

            if !item.redAlliance.isEmpty || !item.blueAlliance.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Text(L10n.text(.redAlliance, language: appLanguage))
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(L10n.text(.blueAlliance, language: appLanguage))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.97))
                    .padding(.bottom, 5)

                    HStack(spacing: 0) {
                        allianceColumn(teams: item.redAlliance, background: Color(red: 0.38, green: 0.06, blue: 0.12))
                        allianceColumn(teams: item.blueAlliance, background: Color(red: 0.05, green: 0.20, blue: 0.42))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.42))
    }

    private func allianceColumn(teams: [String], background: Color) -> some View {
        VStack(spacing: 3) {
            ForEach(teams, id: \.self) { team in
                Text(teamNumber == team ? "⭐ \(team)" : team)
                    .font(.system(.body, design: .rounded).weight(teamNumber == team ? .bold : .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
            if teams.isEmpty {
                Text("-")
                    .foregroundColor(.white.opacity(0.75))
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(background)
    }

    private func rowBackground(for item: NexusUpcomingQueueItem) -> some ShapeStyle {
        switch item.accentAlliance {
        case .red:
            return LinearGradient(
                colors: [Color(red: 0.36, green: 0.04, blue: 0.10), Color(red: 0.23, green: 0.02, blue: 0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .blue:
            return LinearGradient(
                colors: [Color(red: 0.03, green: 0.14, blue: 0.33), Color(red: 0.01, green: 0.08, blue: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .neutral:
            return LinearGradient(
                colors: [Color(red: 0.21, green: 0.22, blue: 0.25), Color(red: 0.15, green: 0.16, blue: 0.19)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func localizedQueueSubtitle(for item: NexusUpcomingQueueItem) -> String? {
        if isBreakLabel(item.title) {
            guard let subtitle = item.subtitle else { return nil }
            if appLanguage == .tr, subtitle.lowercased().hasPrefix("after match ") {
                let suffix = subtitle.dropFirst("After match ".count)
                return "Maç \(suffix) sonrasında"
            }
            return subtitle
        }
        if let t = item.estimatedQueueTime ?? item.subtitle {
            return appLanguage == .tr ? "~\(t) gibi sıraya alınacak" : "~Queued around \(t)"
        }
        return item.subtitle
    }

    private func localizedBreakTitle(_ raw: String) -> String {
        let n = raw.lowercased()
        if n.contains("lunch") || n.contains("öğle") {
            return appLanguage == .tr ? "Öğle Arası" : "Lunch Break"
        }
        if n.contains("day end") || n.contains("gün sonu") || n.contains("gun sonu") {
            return appLanguage == .tr ? "Gün Sonu" : "Day End"
        }
        if n.contains("break") {
            return appLanguage == .tr ? "Ara" : "Break"
        }
        return raw
    }

    private func isBreakLabel(_ label: String) -> Bool {
        let n = label.lowercased()
        return n.contains("lunch") || n.contains("öğle") || n.contains("gün sonu") || n.contains("gun sonu") || n.contains("day end") || n.contains("break")
    }

    @MainActor
    private func loadBoard() async {
        guard !selectedEventCode.isEmpty, let team = Int(teamNumber) else { return }
        await backfillSelectedEventEndDateIfNeeded()
        if isSelectedEventCompleted {
            board = NexusQueuingBoardSnapshot(divisionName: selectedEventName, currentMatchOnField: "-", entries: [])
            errorMessage = nil
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loaded = try await NexusAPIClient.shared.fetchQueuingBoard(eventCode: selectedEventCode, teamNumber: team)
            board = loaded
            expandedIDs = Set(loaded.entries.prefix(1).map(\.id))
        } catch {
            if let nexusError = error as? NexusAPIClientError {
                errorMessage = nexusError.errorDescription ?? L10n.text(.liveDataError, language: appLanguage)
            } else {
                errorMessage = L10n.text(.liveDataError, language: appLanguage)
            }
        }
    }

    private var isSelectedEventCompleted: Bool {
        TBAEventCalendar.isStoredEventPastEnd(endYyyyMmDd: selectedEventEndDate)
    }

    @MainActor
    private func backfillSelectedEventEndDateIfNeeded() async {
        guard selectedEventEndDate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !selectedEventCode.isEmpty,
              !teamNumber.isEmpty,
              teamNumber != "99999" else { return }

        do {
            let events = try await TBAAPIClient.shared.fetchTeamEvents2026(teamNumber: teamNumber)
            let normalizedCode = selectedEventCode.lowercased()
            guard let event = events.first(where: {
                $0.eventCode.lowercased() == normalizedCode || $0.eventKey.lowercased() == normalizedCode
            }) else { return }

            selectedEventEndDate = event.endDate
            if selectedEventDate.isEmpty {
                selectedEventDate = event.startDate
            }
        } catch {}
    }
}
