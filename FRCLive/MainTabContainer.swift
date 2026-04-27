import SwiftUI

struct MainTabContainer: View {
    @State private var selectedTab: Tab = .dashboard

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(Tab.dashboard)

                ScheduleView()
                    .tag(Tab.schedule)

                SettingsView()
                    .tag(Tab.settings)
            }
            .toolbar(.hidden, for: .tabBar)

            liquidGlassTabBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var liquidGlassTabBar: some View {
        HStack(spacing: 24) {
            tabButton(tab: .dashboard, icon: "house.fill", title: "Dashboard")
            tabButton(tab: .schedule, icon: "calendar", title: "Schedule")
            tabButton(tab: .settings, icon: "gearshape.fill", title: "Settings")
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.75), Color.white.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
    }

    private func tabButton(tab: Tab, icon: String, title: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                Text(title)
                    .font(.caption2.weight(.medium))
            }
            .foregroundColor(selectedTab == tab ? .black : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selectedTab == tab ? Color.white.opacity(0.7) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

private enum Tab {
    case dashboard
    case schedule
    case settings
}

private struct ScheduleView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                Text("Event match list buraya gelecek.")
                    .foregroundColor(.gray)
            }
            .navigationTitle("Schedule")
        }
    }
}

#Preview {
    MainTabContainer()
}
