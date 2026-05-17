import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("teamNickname") private var teamNickname: String = ""
    @AppStorage("teamAvatarURL") private var teamAvatarURL: String = ""
    @AppStorage("selectedEventCode") private var selectedEventCode: String = ""
    @AppStorage("selectedEventName") private var selectedEventName: String = ""
    @AppStorage("selectedEventDate") private var selectedEventDate: String = ""
    @AppStorage("selectedEventEndDate") private var selectedEventEndDate: String = ""
    @AppStorage("liveActivitiesEnabled") private var liveActivitiesEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue

    @State private var infoMessage: String?
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .tr }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(L10n.text(.liveActivitiesToggle, language: appLanguage), isOn: $liveActivitiesEnabled)
                        .tint(.blue)
                        .onChange(of: liveActivitiesEnabled) { _, newValue in
                            if !newValue {
                                Task { await LiveActivityManager.shared.end() }
                            }
                        }

                    Toggle(L10n.text(.notificationsToggle, language: appLanguage), isOn: $notificationsEnabled)
                        .tint(.blue)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                requestNotificationPermission()
                            } else {
                                Task { await QueueReminderScheduler.cancelAll() }
                            }
                        }

                    Button(L10n.text(.testNotification, language: appLanguage)) {
                        triggerTestNotification()
                    }
                    .foregroundColor(.primary)

                    Text(L10n.text(.notificationsBackgroundNote, language: appLanguage))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section(L10n.text(.language, language: appLanguage)) {
                    Picker(L10n.text(.language, language: appLanguage), selection: $appLanguageRaw) {
                        Text("TR").tag(AppLanguage.tr.rawValue)
                        Text("EN").tag(AppLanguage.en.rawValue)
                    }
                    .pickerStyle(.segmented)
                }

                Section(L10n.text(.theme, language: appLanguage)) {
                    Picker(L10n.text(.theme, language: appLanguage), selection: $appThemeRaw) {
                        Text(L10n.text(.themeSystem, language: appLanguage)).tag(AppTheme.system.rawValue)
                        Text(L10n.text(.themeLight, language: appLanguage)).tag(AppTheme.light.rawValue)
                        Text(L10n.text(.themeDark, language: appLanguage)).tag(AppTheme.dark.rawValue)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button {
                        selectedEventCode = ""
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.text(.eventSelection, language: appLanguage))
                                    .foregroundColor(.primary)
                                if !selectedEventName.isEmpty {
                                    Text(selectedEventName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.secondary.opacity(0.55))
                        }
                    }

                    Button(L10n.text(.logout, language: appLanguage), role: .destructive) {
                        logout()
                    }
                }

                if let infoMessage {
                    Section {
                        Text(infoMessage)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    VStack(spacing: 8) {
                        Text(appVersionLabel)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Link(L10n.text(.poweredBy, language: appLanguage), destination: URL(string: "https://onurakyuz.com")!)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemGroupedBackground))
            .frcliveTabScreenTitle(L10n.text(.settings, language: appLanguage))
        }
    }

    private var appVersionLabel: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.3"
        let format = L10n.text(.appVersionFormat, language: appLanguage)
        return String(format: format, locale: Locale(identifier: "en_US_POSIX"), version)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                notificationsEnabled = granted
                infoMessage = granted
                    ? L10n.text(.notificationPermissionGranted, language: appLanguage)
                    : L10n.text(.notificationPermissionDenied, language: appLanguage)
                if granted {
                    WidgetBackgroundRefreshManager.schedule(urgent: true)
                    Task { @MainActor in
                        _ = await WidgetBackgroundRefreshManager.performWidgetRefresh()
                    }
                }
            }
        }
    }

    private func triggerTestNotification() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                scheduleTestNotification()
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async {
                        notificationsEnabled = granted
                    }
                    if granted {
                        scheduleTestNotification()
                    } else {
                        DispatchQueue.main.async {
                            infoMessage = L10n.text(.notificationPermissionDenied, language: appLanguage)
                        }
                    }
                }
            case .denied:
                DispatchQueue.main.async {
                    notificationsEnabled = false
                    infoMessage = L10n.text(.notificationPermissionDenied, language: appLanguage)
                }
            @unknown default:
                DispatchQueue.main.async {
                    infoMessage = L10n.text(.testNotificationFailed, language: appLanguage)
                }
            }
        }
    }

    private func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = L10n.notificationHeader(
            type: appLanguage == .tr ? "Test" : "Test"
        )
        content.body = appLanguage == .tr ? "Canlı takip bildirim sistemi çalışıyor." : "Live tracking notification system is working."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "frclive-test-\(UUID().uuidString)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error {
                    infoMessage = "\(L10n.text(.testNotificationFailed, language: appLanguage)) \(error.localizedDescription)"
                } else {
                    notificationsEnabled = true
                    infoMessage = L10n.text(.testNotificationSent, language: appLanguage)
                }
            }
        }
    }

    private func logout() {
        let previousTeam = teamNumber
        Task {
            await LiveActivityManager.shared.end()
        }
        AnnouncementStore.shared.resetForLogout()
        if !previousTeam.isEmpty {
            TBAAPIClient.shared.clearCachedTeamAvatar(teamNumber: previousTeam)
        }
        teamAvatarURL = ""
        teamNickname = ""
        teamNumber = ""
        selectedEventCode = ""
        selectedEventName = ""
        selectedEventDate = ""
        selectedEventEndDate = ""
    }
}

#Preview {
    SettingsView()
}
