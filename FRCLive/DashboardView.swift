import SwiftUI

struct DashboardView: View {
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("selectedEventName") private var selectedEventName: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Hoş Geldiniz Takım \(teamNumber)")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.black)

                    Text(selectedEventName.isEmpty ? "Etkinlik seçilmedi" : selectedEventName)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    liveMatchCard
                    liveActivityStatus
                }
                .padding(20)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Dashboard")
        }
    }

    private var liveMatchCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Next Match")
                .font(.headline)
                .foregroundColor(.black)

            Text("Veri yakında Nexus ile güncellenecek")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.black.opacity(0.12), Color.black.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private var liveActivityStatus: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
            Text("Live Activity: Hazır")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.black)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

#Preview {
    DashboardView()
}
