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
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .tr }
    @State private var matches: [TBASimpleMatch] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedSection: MatchSection = .qualification

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
                        Picker(L10n.text(.schedule, language: appLanguage), selection: $selectedSection) {
                            Text(L10n.text(.practice, language: appLanguage)).tag(MatchSection.practice)
                            Text(L10n.text(.qualification, language: appLanguage)).tag(MatchSection.qualification)
                            Text(L10n.text(.playoff, language: appLanguage)).tag(MatchSection.playoff)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        List(filteredMatches) { match in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(matchTitle(match))
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("\(L10n.text(.redAlliance, language: appLanguage)): \(allianceTeams(match.alliances.red.teamKeys))")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)

                                Text("\(L10n.text(.blueAlliance, language: appLanguage)): \(allianceTeams(match.alliances.blue.teamKeys))")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
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
                }
            }
            .task {
                await loadMatches()
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
        } catch {
            errorMessage = L10n.text(.invalidTeamOrEvents, language: appLanguage)
        }
    }

    private func matchTitle(_ match: TBASimpleMatch) -> String {
        let level: String
        switch match.compLevel {
        case "qm":
            level = "Qual"
        case "qf":
            level = "QF"
        case "sf":
            level = "SF"
        case "f":
            level = "Final"
        default:
            level = L10n.text(.matchLabel, language: appLanguage)
        }
        return "\(level) \(match.matchNumber)"
    }

    private func allianceTeams(_ teamKeys: [String]) -> String {
        teamKeys
            .map { $0.replacingOccurrences(of: "frc", with: "") }
            .joined(separator: ", ")
    }

    private var filteredMatches: [TBASimpleMatch] {
        matches.filter { selectedSection.includes(compLevel: $0.compLevel) }
    }
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
    @State private var showAllAwardRecipients = false

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
                            Task { await loadRankings() }
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
                                    ForEach(rankings) { entry in
                                        HStack(spacing: 10) {
                                            Text("#\(entry.rank)")
                                                .font(.footnote.weight(.bold))
                                                .foregroundColor(.secondary)
                                                .frame(width: 38, alignment: .leading)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(entry.teamKey.replacingOccurrences(of: "frc", with: ""))
                                                    .font(.headline)
                                                Text(entry.teamName)
                                                    .font(.footnote)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }

                                            Spacer()

                                            Text("\(entry.record.wins) / \(entry.record.losses) / \(entry.record.ties)")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(isOwnTeam(entry.teamKey) ? .blue : .primary)
                                        }
                                        .padding(.vertical, 4)
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

        do {
            async let fetchedRankings = TBAAPIClient.shared.fetchEventRankings(eventCode: selectedEventCode)
            async let fetchedAwards = TBAAPIClient.shared.fetchEventAwards(eventCode: selectedEventCode)
            rankings = try await fetchedRankings
            awards = try await fetchedAwards
        } catch {
            errorMessage = L10n.text(.invalidTeamOrEvents, language: appLanguage)
        }
    }

    private func isOwnTeam(_ teamKey: String) -> Bool {
        teamKey == "frc\(teamNumber)"
    }

    private func awardRecipientsText(_ award: TBAAward) -> String {
        let recipients = award.recipients.compactMap { $0.teamKey?.replacingOccurrences(of: "frc", with: "") }
        guard !recipients.isEmpty else { return "-" }
        return recipients.joined(separator: ", ")
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
}

private enum RankingsSection {
    case rankings
    case awards
}

#Preview {
    MainTabContainer()
}
