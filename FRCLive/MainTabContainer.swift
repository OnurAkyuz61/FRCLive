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

            SettingsView()
                .tabItem {
                    Label(L10n.text(.settings, language: appLanguage), systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(.black)
    }
}

private enum Tab {
    case dashboard
    case schedule
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
                        Text(L10n.text(.noMatchesForTeam, language: appLanguage))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Link(L10n.text(.poweredBy, language: appLanguage), destination: URL(string: "https://onurakyuz.com")!)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                } else {
                    List(matches) { match in
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
}

#Preview {
    MainTabContainer()
}
