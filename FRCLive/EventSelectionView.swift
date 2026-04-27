import SwiftUI

struct EventSelectionView: View {
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("selectedEventCode") private var selectedEventCode: String = ""
    @AppStorage("selectedEventName") private var selectedEventName: String = ""

    @State private var events: [TBAEvent] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                Group {
                    if isLoading {
                        ProgressView("Etkinlikler yükleniyor...")
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
                        List(events) { event in
                            Button {
                                selectedEventCode = event.eventCode
                                selectedEventName = event.name
                            } label: {
                                EventCardView(event: event)
                            }
                            .buttonStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Etkinlik Seçimi")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("Takım \(teamNumber)")
                        .font(.subheadline.weight(.medium))
                }
            }
            .task {
                await loadEvents()
            }
        }
    }

    @MainActor
    private func loadEvents() async {
        guard !teamNumber.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            events = try await TBAAPIClient.shared.fetchTeamEvents2026(teamNumber: teamNumber)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(event.name)
                .font(.headline)
                .foregroundColor(.black)

            Text(event.city ?? "Konum belirtilmedi")
                .font(.subheadline)
                .foregroundColor(.gray)

            Text("Tarih: \(event.date)")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.black.opacity(0.15), Color.black.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

#Preview {
    EventSelectionView()
}
