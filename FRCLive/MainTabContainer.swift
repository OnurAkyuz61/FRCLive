import SwiftUI

struct MainTabContainer: View {
    @AppStorage("selectedEventCode") private var selectedEventCode: String = ""
    @State private var selectedTab: Tab = .dashboard

    var body: some View {
        ZStack {
            switch selectedTab {
            case .dashboard:
                DashboardView()
            case .schedule:
                ScheduleView()
            case .settings:
                SettingsView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            liquidGlassTabBar
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var liquidGlassTabBar: some View {
        HStack(spacing: 24) {
            tabButton(tab: .dashboard, icon: "house.fill", title: "Dashboard")
            tabButton(tab: .schedule, icon: "calendar", title: "Schedule")
            tabButton(tab: .settings, icon: "gearshape.fill", title: "Settings")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.85),
                                    Color.blue.opacity(0.25),
                                    Color.purple.opacity(0.22),
                                    Color.white.opacity(0.40)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.35
                        )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }

    private func tabButton(tab: Tab, icon: String, title: String) -> some View {
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .scaleEffect(selectedTab == tab ? 1.08 : 1.0)
                Text(title)
                    .font(.caption2.weight(.medium))
                    .scaleEffect(selectedTab == tab ? 1.03 : 1.0)
            }
            .foregroundColor(selectedTab == tab ? .black : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selectedTab == tab ? Color.white.opacity(0.75) : Color.clear)
            )
            .offset(y: selectedTab == tab ? -1 : 0)
            .animation(.spring(response: 0.30, dampingFraction: 0.86), value: selectedTab == tab)
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
