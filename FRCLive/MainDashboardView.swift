import SwiftUI

struct MainDashboardView: View {
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @State private var events: [TBAEvent] = []
    @State private var queueData: NexusQueue?
    @State private var errorMessage: String?
    @State private var isLoadingEvents = false
    @State private var selectedLiveEventCode: String?
    @State private var showSettings = false
    @State private var settingsTeamNumber = ""
    @FocusState private var settingsFieldFocused: Bool

    @State private var pollingTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Hoş Geldiniz, Takım \(teamNumber)")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.black)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }

                if isLoadingEvents {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Etkinlikler yükleniyor...")
                            Spacer()
                        }
                    }
                } else {
                    Section("2026 Etkinlikleri") {
                        if events.isEmpty {
                            Text("Bu takım için 2026 etkinliği bulunamadı.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(events) { event in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(event.name)
                                            .font(.headline)
                                            .foregroundColor(.black)
                                        Spacer()
                                        if isEventActive(event) {
                                            Text("AKTIF")
                                                .font(.caption2.weight(.bold))
                                                .foregroundColor(.green)
                                        }
                                    }

                                    Text(event.city ?? "Konum belirtilmedi")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)

                                    Text("Tarih: \(event.date)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)

                                    if isEventActive(event) {
                                        Button("Canlı Takip Başlat") {
                                            startQueuePolling(for: event.eventCode)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.blue)
                                    }

                                    if selectedLiveEventCode == event.eventCode, let queueData {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Canlı Kuyruk Verisi")
                                                .font(.subheadline.weight(.semibold))
                                            Text("Maç: \(queueData.currentMatch)")
                                            Text("Tahmini Başlangıç: \(queueData.estimatedTime)")
                                            Text("Durum: \(queueData.status)")
                                        }
                                        .font(.footnote)
                                        .foregroundColor(.black)
                                        .padding(10)
                                        .background(Color.gray.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    }
                                }
                                .padding(.vertical, 6)
                                .listRowBackground(isEventActive(event) ? Color.green.opacity(0.08) : Color.white)
                            }
                        }
                    }
                }
            }
            .navigationTitle("FRCLive")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Ayarlar") {
                        settingsTeamNumber = teamNumber
                        showSettings = true
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Takım numarasını güncelle")
                            .font(.headline)

                        TextField(
                            "örn. 6232",
                            text: Binding(
                                get: { settingsTeamNumber },
                                set: { settingsTeamNumber = String($0.filter(\.isNumber).prefix(5)) }
                            )
                        )
                        .keyboardType(.numberPad)
                        .textInputAutocapitalization(.never)
                        .focused($settingsFieldFocused)
                        .padding(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                        )

                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                        }

                        Button("Kaydet ve Yenile") {
                            Task {
                                await saveAndRefreshTeamNumber()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(settingsTeamNumber.isEmpty)

                        Spacer()
                    }
                    .padding(20)
                    .navigationTitle("Ayarlar")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Kapat") {
                                showSettings = false
                            }
                        }
                    }
                }
            }
            .task {
                await loadEvents()
            }
            .onDisappear {
                pollingTask?.cancel()
            }
        }
    }

    private func loadEvents() async {
        isLoadingEvents = true
        errorMessage = nil
        defer { isLoadingEvents = false }

        do {
            events = try await FRCService.shared.fetchTeamEvents2026(teamNumber: teamNumber)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveAndRefreshTeamNumber() async {
        let trimmed = settingsTeamNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            try await FRCService.shared.validateTeam(teamNumber: trimmed)
            teamNumber = trimmed
            showSettings = false
            pollingTask?.cancel()
            selectedLiveEventCode = nil
            queueData = nil
            await loadEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func isEventActive(_ event: TBAEvent) -> Bool {
        guard let eventDate = DateFormatter.tbaDateFormatter.date(from: event.date) else {
            return false
        }
        return Calendar.current.isDateInToday(eventDate)
    }

    private func startQueuePolling(for eventCode: String) {
        pollingTask?.cancel()
        selectedLiveEventCode = eventCode
        errorMessage = nil

        pollingTask = Task {
            while !Task.isCancelled {
                do {
                    let latest = try await FRCService.shared.fetchLiveQueuingData(eventCode: eventCode)
                    await MainActor.run {
                        queueData = latest
                        errorMessage = nil
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Canlı kuyruk verisi alınamadı: \(error.localizedDescription)"
                    }
                }

                do {
                    try await Task.sleep(nanoseconds: 15_000_000_000)
                } catch {
                    break
                }
            }
        }
    }
}

private extension DateFormatter {
    static let tbaDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

#Preview {
    MainDashboardView()
}
