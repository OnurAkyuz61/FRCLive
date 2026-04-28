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
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .tr }

    @State private var rankings: [TBARankingEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

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
                } else if rankings.isEmpty {
                    Text(L10n.text(.noRankings, language: appLanguage))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                } else {
                    List(rankings) { entry in
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

                            Text("\(L10n.text(.wins, language: appLanguage)) \(entry.record.wins)")
                                .font(.caption.weight(.semibold))
                            Text("\(L10n.text(.losses, language: appLanguage)) \(entry.record.losses)")
                                .font(.caption.weight(.semibold))
                            Text("\(L10n.text(.ties, language: appLanguage)) \(entry.record.ties)")
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await loadRankings() }
                }
            }
            .navigationTitle(L10n.text(.rankings, language: appLanguage))
            .task {
                await loadRankings()
            }
        }
    }

    @MainActor
    private func loadRankings() async {
        guard !selectedEventCode.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            rankings = try await TBAAPIClient.shared.fetchEventRankings(eventCode: selectedEventCode)
        } catch {
            errorMessage = L10n.text(.invalidTeamOrEvents, language: appLanguage)
        }
    }
}

#Preview {
    MainTabContainer()
}
