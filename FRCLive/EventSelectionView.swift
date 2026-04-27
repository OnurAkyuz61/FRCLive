import SwiftUI

struct EventSelectionView: View {
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("selectedEventCode") private var selectedEventCode: String = ""
    @AppStorage("selectedEventName") private var selectedEventName: String = ""
    @AppStorage("teamNickname") private var teamNickname: String = ""
    @AppStorage("teamAvatarURL") private var teamAvatarURL: String = ""

    @State private var events: [TBAEvent] = []
    @State private var teamName: String = "Overcharge"
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                Group {
                    if isLoading {
                        VStack(spacing: 10) {
                            ProgressView()
                            Text("Etkinlikler yükleniyor...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else if let errorMessage {
                        VStack(spacing: 12) {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                            Button("Tekrar Dene") {
                                Task { await loadEvents() }
                            }
                        }
                        .padding(.horizontal, 24)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 18) {
                                headerSection

                                VStack(spacing: 12) {
                                    ForEach(events) { event in
                                        Button {
                                            selectedEventCode = event.eventCode
                                            selectedEventName = event.name
                                        } label: {
                                            EventCardView(event: event)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                footer
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        teamNumber = ""
                        selectedEventCode = ""
                        selectedEventName = ""
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Takım Seçimi")
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .task {
                await loadEvents()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(teamName)
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
                .lineLimit(2)

            HStack(spacing: 10) {
                Text("Takım \(teamNumber)")
                    .font(.title3)
                    .foregroundColor(.secondary)

                TeamAvatarView(avatarURLString: teamAvatarURL, size: 34)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Link("Powered by Onur Akyüz", destination: URL(string: "https://onurakyuz.com")!)
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.top, 8)
    }

    @MainActor
    private func loadEvents() async {
        guard !teamNumber.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let profile = TBAAPIClient.shared.fetchTeamProfile(teamNumber: teamNumber)
            async let fetchedEvents = TBAAPIClient.shared.fetchTeamEvents2026(teamNumber: teamNumber)
            async let avatarURL = TBAAPIClient.shared.fetchTeamAvatarURL(teamNumber: teamNumber)

            let (fetchedProfile, allEvents, fetchedAvatarURL) = try await (profile, fetchedEvents, avatarURL)
            if let nickname = fetchedProfile.nickname, !nickname.isEmpty {
                teamName = nickname
                teamNickname = nickname
            } else {
                teamName = "Overcharge"
                teamNickname = ""
            }
            events = allEvents
            teamAvatarURL = fetchedAvatarURL?.absoluteString ?? ""
            if events.isEmpty {
                errorMessage = "Bu takım için 2026 etkinliği bulunamadı."
            }
        } catch {
            errorMessage = "Etkinlikler yüklenemedi veya geçersiz takım."
        }
    }
}

private struct EventCardView: View {
    let event: TBAEvent

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text(event.name)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text(event.date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.secondary)
                    Text(event.city ?? "Konum belirtilmedi")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    EventSelectionView()
}
