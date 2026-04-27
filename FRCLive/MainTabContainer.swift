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
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .tr }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 12) {
                    Text("Event match list buraya gelecek.")
                        .foregroundColor(.gray)
                    Link(L10n.text(.poweredBy, language: appLanguage), destination: URL(string: "https://onurakyuz.com")!)
                        .font(.footnote)
                        .foregroundColor(.secondary)
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
        }
    }
}

#Preview {
    MainTabContainer()
}
