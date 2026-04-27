import SwiftUI

struct MainTabContainer: View {
    @State private var selectedTab: Tab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(Tab.dashboard)

            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(Tab.schedule)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
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

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 12) {
                    Text("Event match list buraya gelecek.")
                        .foregroundColor(.gray)
                    Link("Powered by Onur Akyüz", destination: URL(string: "https://onurakyuz.com")!)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Etkinlik Seçimi") {
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
