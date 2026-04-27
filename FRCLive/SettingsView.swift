import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("selectedEventCode") private var selectedEventCode: String = ""
    @AppStorage("selectedEventName") private var selectedEventName: String = ""
    @AppStorage("liveActivitiesEnabled") private var liveActivitiesEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    @State private var infoMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                List {
                    Section {
                        glassRow {
                            Toggle("Canlı Etkinlikleri (Live Activities) Aç", isOn: $liveActivitiesEnabled)
                                .tint(.blue)
                        }

                        glassRow {
                            Toggle("Bildirimleri İzin Ver", isOn: $notificationsEnabled)
                                .tint(.blue)
                                .onChange(of: notificationsEnabled) { _, newValue in
                                    if newValue {
                                        requestNotificationPermission()
                                    }
                                }
                        }

                        glassRow {
                            Button("Bildirimi Test Et") {
                                triggerTestNotification()
                            }
                            .foregroundColor(.black)
                        }
                    }

                    Section {
                        Button("Çıkış Yap", role: .destructive) {
                            logout()
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.red.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.red.opacity(0.25), lineWidth: 1)
                                )
                        )
                    }

                    if let infoMessage {
                        Section {
                            Text(infoMessage)
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }

                    Section {
                        HStack {
                            Spacer()
                            Link("Powered by Onur Akyüz", destination: URL(string: "https://onurakyuz.com")!)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Etkinlik Seçimi") {
                        selectedEventCode = ""
                    }
                }
            }
        }
    }

    private func glassRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.vertical, 4)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
            )
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                notificationsEnabled = granted
                infoMessage = granted ? "Bildirim izni verildi." : "Bildirim izni verilmedi."
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
                    infoMessage = "Bildirim gönderilemedi: \(error.localizedDescription)"
                } else {
                    infoMessage = "2 saniye içinde test bildirimi gönderilecek."
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
