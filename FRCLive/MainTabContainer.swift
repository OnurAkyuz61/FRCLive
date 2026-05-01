import SwiftUI

struct MainTabContainer: View {
    @State private var selectedTab: Tab = .dashboard
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .tr }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(L10n.text(.dashboard, language: appLanguage), systemImage: "house.fill")
                }
                .tag(Tab.dashboard)

            ScheduleView()
                .tabItem {
                    Label(L10n.text(.schedule, language: appLanguage), systemImage: "calendar")
                }
                .tag(Tab.schedule)

            RankingsView()
                .tabItem {
                    Label(L10n.text(.rankings, language: appLanguage), systemImage: "list.number")
                }
                .tag(Tab.rankings)

            SettingsView()
                .tabItem {
                    Label(L10n.text(.settings, language: appLanguage), systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(.black)
        .id(appLanguageRaw)
    }
}

private enum Tab {
    case dashboard
    case schedule
    case rankings
    case settings
}

private struct ScheduleView: View {
    @AppStorage("selectedEventCode") private var selectedEventCode: String = ""
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("selectedEventDate") private var selectedEventDate: String = ""
    @AppStorage("selectedEventEndDate") private var selectedEventEndDate: String = ""
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .tr }
    @State private var matches: [TBASimpleMatch] = []
    @State private var queueSnapshot: NexusTeamQueueSnapshot?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedSection: MatchSection = .qualification
    @State private var showUpcomingMatches = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                if isLoading {
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
                            Task { await loadMatches() }
                        }
                    }
                    .padding(.horizontal, 24)
                } else if matches.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text(L10n.text(.matchScheduleNotCreated, language: appLanguage))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Link(L10n.text(.poweredBy, language: appLanguage), destination: URL(string: "https://onurakyuz.com")!)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 10) {
                        if !isSelectedEventCompleted {
                            Button {
                                showUpcomingMatches = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "list.bullet.rectangle.portrait")
                                    Text(appLanguage == .tr ? "Yaklaşan Maçlar (Nexus)" : "Upcoming Matches (Nexus)")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                }
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }

                        if isSelectedEventCompleted {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.orange)
                                Text(L10n.text(.eventCompletedBanner, language: appLanguage))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.orange.opacity(0.30), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        } else if let queueSnapshot {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.badge.checkmark")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(queueSnapshot.teamNextMatch ?? "-")
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(L10n.text(.estimatedStart, language: appLanguage)): \(queueSnapshot.estimatedStartTime ?? "-")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }

                        Picker(L10n.text(.schedule, language: appLanguage), selection: $selectedSection) {
                            Text(L10n.text(.practice, language: appLanguage)).tag(MatchSection.practice)
                            Text(L10n.text(.qualification, language: appLanguage)).tag(MatchSection.qualification)
                            Text(L10n.text(.playoff, language: appLanguage)).tag(MatchSection.playoff)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        List(filteredMatches) { match in
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Text(matchTitle(match))
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        if matchIncludesOurTeam(match) {
                                            Text("TEAM")
                                                .font(.caption2.weight(.bold))
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(Color.yellow.opacity(0.9))
                                                .clipShape(Capsule())
                                        }
                                    }

                                    Text(matchDateTimeText(match))
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text("\(L10n.text(.redAlliance, language: appLanguage)): \(allianceTeams(match.alliances.red.teamKeys))")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)

                                    Text("\(L10n.text(.blueAlliance, language: appLanguage)): \(allianceTeams(match.alliances.blue.teamKeys))")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }

                                Spacer(minLength: 4)

                                scoreBanner(for: match)
                            }
                            .padding(.vertical, 4)
                        }
                        .listStyle(.insetGrouped)
                        .refreshable { await loadMatches() }
                    }
                }
            }
            .navigationTitle(L10n.text(.schedule, language: appLanguage))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.text(.eventSelection, language: appLanguage)) {
                        selectedEventCode = ""
                    }
                    .foregroundColor(.primary)
                }
            }
            .task {
                await loadMatches()
            }
            .sheet(isPresented: $showUpcomingMatches) {
                NavigationStack {
                    ScheduleUpcomingMatchesSheet()
                }
            }
        }
    }

    @MainActor
    private func loadMatches() async {
        guard !selectedEventCode.isEmpty else { return }
        guard let teamInt = Int(teamNumber) else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let allMatches = try await TBAAPIClient.shared.fetchEventMatches(eventCode: selectedEventCode)
            let teamKey = "frc\(teamInt)"
            matches = allMatches.filter { match in
                match.alliances.red.teamKeys.contains(teamKey) || match.alliances.blue.teamKeys.contains(teamKey)
            }
            if isSelectedEventCompleted {
                queueSnapshot = nil
            } else {
                queueSnapshot = try? await NexusAPIClient.shared.fetchQueueSnapshot(
                    eventCode: selectedEventCode,
                    teamNumber: teamInt
                )
            }
        } catch {
            errorMessage = L10n.text(.invalidTeamOrEvents, language: appLanguage)
        }
    }

    private var isSelectedEventCompleted: Bool {
        let end = selectedEventEndDate.isEmpty ? selectedEventDate : selectedEventEndDate
        guard let date = DateFormatter.mainTabTBAEventDate.date(from: end) else { return false }
        return date < Calendar.current.startOfDay(for: Date())
    }

    private func matchTitle(_ match: TBASimpleMatch) -> String {
        switch match.compLevel {
        case "qm":
            return "Qual \(match.matchNumber)"
        case "f":
            if match.matchNumber == 1 { return "Final 1" }
            if match.matchNumber == 2 { return "Final 2" }
            return "Final Tiebreaker"
        case "qf", "sf", "ef":
            if match.matchNumber <= 1 {
                return "\(L10n.text(.matchLabel, language: appLanguage)) \(match.setNumber)"
            }
            return "\(L10n.text(.matchLabel, language: appLanguage)) \(match.setNumber)-\(match.matchNumber)"
        default:
            return "\(L10n.text(.matchLabel, language: appLanguage)) \(match.matchNumber)"
        }
    }

    private func allianceTeams(_ teamKeys: [String]) -> String {
        teamKeys
            .map { key in
                let team = key.replacingOccurrences(of: "frc", with: "")
                return key == currentTeamKey ? "⭐\(team)" : team
            }
            .joined(separator: ", ")
    }

    private var filteredMatches: [TBASimpleMatch] {
        matches.filter { selectedSection.includes(compLevel: $0.compLevel) }
    }

    private var currentTeamKey: String {
        "frc\(teamNumber)"
    }

    private func matchIncludesOurTeam(_ match: TBASimpleMatch) -> Bool {
        match.alliances.red.teamKeys.contains(currentTeamKey) || match.alliances.blue.teamKeys.contains(currentTeamKey)
    }

    private func scoreBanner(for match: TBASimpleMatch) -> some View {
        let redScore = displayScore(match.alliances.red.score)
        let blueScore = displayScore(match.alliances.blue.score)
        let resultColor = resultBannerColor(for: match)

        return VStack(alignment: .leading, spacing: 4) {
            Text("R: \(redScore)")
                .font(.caption.weight(.semibold))
            Text("B: \(blueScore)")
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(resultColor)
        )
    }

    private func displayScore(_ score: Int?) -> String {
        guard let score, score >= 0 else { return "-" }
        return String(score)
    }

    private func resultBannerColor(for match: TBASimpleMatch) -> Color {
        guard let red = match.alliances.red.score, red >= 0,
              let blue = match.alliances.blue.score, blue >= 0 else {
            return .gray
        }

        let teamIsRed = match.alliances.red.teamKeys.contains(currentTeamKey)
        let teamIsBlue = match.alliances.blue.teamKeys.contains(currentTeamKey)
        guard teamIsRed || teamIsBlue else { return .gray }

        if red == blue { return .orange }

        let ourWon = (teamIsRed && red > blue) || (teamIsBlue && blue > red)
        return ourWon ? .green : .red
    }

    private func matchDateTimeText(_ match: TBASimpleMatch) -> String {
        guard let unix = match.predictedTime ?? match.time, unix > 0 else {
            return appLanguage == .tr ? "Tarih/Saat: -" : "Date/Time: -"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: appLanguage == .tr ? "tr_TR" : "en_US_POSIX")
        formatter.dateFormat = "dd MMM, EEE • HH:mm"
        return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(unix)))
    }
}

private struct ScheduleUpcomingMatchesSheet: View {
    @AppStorage("selectedEventCode") private var selectedEventCode: String = ""
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("selectedEventDate") private var selectedEventDate: String = ""
    @AppStorage("selectedEventEndDate") private var selectedEventEndDate: String = ""
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue
    @AppStorage("selectedEventName") private var selectedEventName: String = ""
    @Environment(\.dismiss) private var dismiss
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .tr }

    @State private var board: NexusQueuingBoardSnapshot?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var expandedIDs: Set<String> = []

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            if isLoading && board == nil {
                ProgressView()
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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(L10n.text(.teamPrefix, language: appLanguage)) \(teamNumber)")
                            .font(.title3.weight(.bold))
                            .padding(.horizontal, 14)
                            .padding(.top, 4)
                        Text(board.divisionName ?? selectedEventName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 14)

                        VStack(spacing: 0) {
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
                                            if expandedIDs.contains(item.id) { expandedIDs.remove(item.id) } else { expandedIDs.insert(item.id) }
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text(localizedBreakTitle(item.title)).foregroundColor(.white)
                                            Spacer()
                                            Text(localizedQueueSubtitle(for: item) ?? "")
                                                .foregroundColor(.white.opacity(0.96))
                                                .lineLimit(1)
                                            Image(systemName: expandedIDs.contains(item.id) ? "chevron.up" : "chevron.down")
                                                .foregroundColor(.white.opacity(0.96))
                                        }
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 12)
                                        .background(rowBg(item.accentAlliance))
                                    }
                                    .buttonStyle(.plain)

                                    if expandedIDs.contains(item.id) {
                                        VStack(alignment: .leading, spacing: 7) {
                                            if isBreakLabel(item.title) {
                                                if let subtitle = localizedQueueSubtitle(for: item) {
                                                    Text("• \(subtitle)")
                                                }
                                                if let resume = item.resumeMatchNumber {
                                                    let timeText = item.scheduledStartTime ?? "-"
                                                    let line = appLanguage == .tr
                                                        ? "• Sıraya alınma Sıralama \(resume) ile birlikte saat ~\(timeText) gibi devam edecek."
                                                        : "• Queuing will continue with Match \(resume) at around ~\(timeText)."
                                                    Text(line)
                                                }
                                            }
                                            if let t = item.estimatedQueueTime {
                                                Label(appLanguage == .tr ? "Tahmini sıra zamanı: \(t)" : "Estimated queue time: \(t)", systemImage: "clock")
                                            }
                                            if let t = item.scheduledStartTime {
                                                Label(appLanguage == .tr ? "Planlanan maç saati: \(t)" : "Planned start time: \(t)", systemImage: "calendar")
                                            }
                                            if !item.redAlliance.isEmpty || !item.blueAlliance.isEmpty {
                                                Text("\(L10n.text(.redAlliance, language: appLanguage)): \(item.redAlliance.joined(separator: ", "))")
                                                Text("\(L10n.text(.blueAlliance, language: appLanguage)): \(item.blueAlliance.joined(separator: ", "))")
                                            }
                                        }
                                        .font(.footnote)
                                        .foregroundColor(.white.opacity(0.97))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.black.opacity(0.42))
                                    }
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.black.opacity(0.10), lineWidth: 1)
                        )
                        .padding(.horizontal, 14)
                    }
                    .padding(.vertical, 10)
                }
                .refreshable { await loadBoard() }
            }
        }
        .navigationTitle(appLanguage == .tr ? "Yaklaşan Maçlar" : "Upcoming Matches")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.text(.alertOk, language: appLanguage)) { dismiss() }
            }
        }
        .task { await loadBoard() }
    }

    private func rowBg(_ alliance: NexusAllianceAccent) -> LinearGradient {
        switch alliance {
        case .red:
            return LinearGradient(colors: [Color(red: 0.36, green: 0.05, blue: 0.10), Color(red: 0.24, green: 0.03, blue: 0.07)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .blue:
            return LinearGradient(colors: [Color(red: 0.03, green: 0.16, blue: 0.34), Color(red: 0.01, green: 0.09, blue: 0.23)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .neutral:
            return LinearGradient(colors: [Color(red: 0.21, green: 0.22, blue: 0.25), Color(red: 0.15, green: 0.16, blue: 0.19)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
        let end = selectedEventEndDate.isEmpty ? selectedEventDate : selectedEventEndDate
        guard let date = DateFormatter.mainTabTBAEventDate.date(from: end) else { return false }
        return date < Calendar.current.startOfDay(for: Date())
    }
}

private extension DateFormatter {
    static let mainTabTBAEventDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private enum MatchSection: CaseIterable {
    case practice
    case qualification
    case playoff

    func includes(compLevel: String) -> Bool {
        switch self {
        case .practice:
            return compLevel == "pm" || compLevel == "pr"
        case .qualification:
            return compLevel == "qm"
        case .playoff:
            return compLevel == "ef" || compLevel == "qf" || compLevel == "sf" || compLevel == "f"
        }
    }
}

private struct RankingsView: View {
    @AppStorage("selectedEventCode") private var selectedEventCode: String = ""
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .tr }

    @State private var rankings: [TBARankingEntry] = []
    @State private var awards: [TBAAward] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedSection: RankingsSection = .rankings
    @State private var showAllAwardRecipients = true
    @State private var eventTeamNameLookup: [String: String] = [:]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text(L10n.text(.loadingEvents, language: appLanguage))
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
                            Task { await loadRankingsAndAwards() }
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 10) {
                        Picker(L10n.text(.rankings, language: appLanguage), selection: $selectedSection) {
                            Text(L10n.text(.rankings, language: appLanguage)).tag(RankingsSection.rankings)
                            Text(L10n.text(.awards, language: appLanguage)).tag(RankingsSection.awards)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        if selectedSection == .rankings && rankings.isEmpty {
                            Text(L10n.text(.noRankings, language: appLanguage))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 24)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if selectedSection == .rankings {
                            List {
                                Section {
                                    ForEach(sortedRankings) { entry in
                                        HStack(spacing: 10) {
                                            Text("#\(entry.rank)")
                                                .font(.footnote.weight(.bold))
                                                .foregroundColor(.secondary)
                                                .frame(width: 38, alignment: .leading)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("\(L10n.text(.teamPrefix, language: appLanguage)) \(entry.teamKey.replacingOccurrences(of: "frc", with: ""))")
                                                    .font(.headline)
                                                Text(resolvedTeamName(for: entry.teamKey, fallbackNumber: entry.teamKey.replacingOccurrences(of: "frc", with: "")))
                                                    .font(.footnote)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                                if isOwnTeam(entry.teamKey) {
                                                    Text("● \(L10n.text(.teamPrefix, language: appLanguage))")
                                                        .font(.caption2.weight(.semibold))
                                                        .foregroundColor(.blue)
                                                }
                                            }

                                            Spacer()

                                            Text("\(entry.record.wins) / \(entry.record.losses) / \(entry.record.ties)")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(isOwnTeam(entry.teamKey) ? .blue : .primary)
                                        }
                                        .padding(.vertical, 4)
                                        .listRowBackground(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(isOwnTeam(entry.teamKey) ? Color.blue.opacity(0.12) : Color.clear)
                                        )
                                    }
                                } header: {
                                    HStack {
                                        Spacer()
                                        Text(L10n.text(.wltHeader, language: appLanguage))
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .listStyle(.insetGrouped)
                            .refreshable { await loadRankingsAndAwards() }
                        } else if awards.isEmpty {
                            Text(L10n.text(.noAwards, language: appLanguage))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 24)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            VStack(spacing: 10) {
                                if filteredAwards.isEmpty {
                                    Text(L10n.text(.noTeamAwards, language: appLanguage))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 24)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    List(filteredAwards) { award in
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(award.name)
                                                .font(.headline)
                                            Text(awardRecipientsText(award))
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .listStyle(.insetGrouped)
                                    .refreshable { await loadRankingsAndAwards() }
                                }

                                Button(showAllAwardRecipients ? L10n.text(.showOnlyTeamAwards, language: appLanguage) : L10n.text(.showAllAwardWinners, language: appLanguage)) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showAllAwardRecipients.toggle()
                                    }
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
            .navigationTitle(L10n.text(.rankings, language: appLanguage))
            .task {
                await loadRankingsAndAwards()
            }
        }
    }

    @MainActor
    private func loadRankingsAndAwards() async {
        guard !selectedEventCode.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var rankingsError: Error?
        var awardsError: Error?

        do {
            rankings = try await TBAAPIClient.shared.fetchEventRankings(eventCode: selectedEventCode)
        } catch {
            rankingsError = error
        }

        do {
            awards = try await TBAAPIClient.shared.fetchEventAwards(eventCode: selectedEventCode)
        } catch {
            awardsError = error
        }

        if let fetchedNameMap = try? await TBAAPIClient.shared.fetchEventTeamNameMap(eventCode: selectedEventCode),
           !fetchedNameMap.isEmpty {
            eventTeamNameLookup = fetchedNameMap
        }

        if rankingsError != nil && awardsError != nil {
            errorMessage = L10n.text(.invalidTeamOrEvents, language: appLanguage)
        } else {
            // Keep currently available section visible even if the other request fails.
            errorMessage = nil
        }
    }

    private func isOwnTeam(_ teamKey: String) -> Bool {
        teamKey == "frc\(teamNumber)"
    }

    private func awardRecipientsText(_ award: TBAAward) -> String {
        let recipients = award.recipients.compactMap { recipient -> String? in
            if let teamKey = recipient.teamKey {
                let teamNumber = teamKey.replacingOccurrences(of: "frc", with: "")
                let teamName = resolvedTeamName(for: teamKey, fallbackNumber: teamNumber)
                if let awardee = recipient.awardee, !awardee.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return "\(awardee) • \(teamNumber) - \(teamName)"
                }
                return "\(teamNumber) - \(teamName)"
            }

            if let teamNumber = recipient.teamNumber {
                let key = "frc\(teamNumber)"
                let teamName = resolvedTeamName(for: key, fallbackNumber: "\(teamNumber)")
                if let awardee = recipient.awardee, !awardee.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return "\(awardee) • \(teamNumber) - \(teamName)"
                }
                return "\(teamNumber) - \(teamName)"
            }

            if let awardee = recipient.awardee, !awardee.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return awardee
            }
            return nil
        }
        guard !recipients.isEmpty else { return "-" }
        return recipients.joined(separator: "\n")
    }

    private var filteredAwards: [TBAAward] {
        if showAllAwardRecipients {
            return awards
        }
        let ownTeamKey = "frc\(teamNumber)"
        return awards.filter { award in
            award.recipients.contains { $0.teamKey == ownTeamKey }
        }
    }

    private var sortedRankings: [TBARankingEntry] {
        rankings.sorted { $0.rank < $1.rank }
    }

    private var teamNameByKey: [String: String] {
        Dictionary(uniqueKeysWithValues: rankings.map { ($0.teamKey, $0.teamName) })
    }

    private func resolvedTeamName(for teamKey: String, fallbackNumber: String) -> String {
        if let fromEventMap = eventTeamNameLookup[teamKey], !fromEventMap.isEmpty {
            return fromEventMap
        }
        if let fromRankings = teamNameByKey[teamKey], !fromRankings.isEmpty {
            return fromRankings
        }
        return fallbackNumber
    }
}

private enum RankingsSection {
    case rankings
    case awards
}

#Preview {
    MainTabContainer()
}
