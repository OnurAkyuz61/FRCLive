import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("selectedEventCode") private var selectedEventCode: String = ""
    @AppStorage("selectedEventName") private var selectedEventName: String = ""
    @AppStorage("liveActivitiesEnabled") private var liveActivitiesEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue

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
                            }
                        }

                    Button(L10n.text(.testNotification, language: appLanguage)) {
                        triggerTestNotification()
                    }
                    .foregroundColor(.primary)
                }

                Section(L10n.text(.language, language: appLanguage)) {
                    Picker(L10n.text(.language, language: appLanguage), selection: $appLanguageRaw) {
                        Text("TR").tag(AppLanguage.tr.rawValue)
                        Text("EN").tag(AppLanguage.en.rawValue)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
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
                    HStack {
                        Spacer()
                        Link(L10n.text(.poweredBy, language: appLanguage), destination: URL(string: "https://onurakyuz.com")!)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(L10n.text(.settings, language: appLanguage))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.text(.eventSelection, language: appLanguage)) {
                        selectedEventCode = ""
                    }
                }
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                notificationsEnabled = granted
                infoMessage = granted
                    ? L10n.text(.notificationPermissionGranted, language: appLanguage)
                    : L10n.text(.notificationPermissionDenied, language: appLanguage)
            }
        }
    }

    private func triggerTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "FRCLive Test Bildirimi"
        content.body = "Canlı takip bildirim sistemi çalışıyor."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error {
                    infoMessage = "\(L10n.text(.testNotificationFailed, language: appLanguage)) \(error.localizedDescription)"
                } else {
                    infoMessage = L10n.text(.testNotificationSent, language: appLanguage)
                }
            }
        }
    }

    private func logout() {
        teamNumber = ""
        selectedEventCode = ""
        selectedEventName = ""
    }
}

#Preview {
    SettingsView()
}
