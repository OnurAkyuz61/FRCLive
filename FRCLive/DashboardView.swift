import SwiftUI

struct DashboardView: View {
    @AppStorage("teamNumber") private var teamNumber: String = ""
    @AppStorage("selectedEventName") private var selectedEventName: String = ""
    @AppStorage("teamNickname") private var teamNickname: String = ""
    @AppStorage("teamAvatarURL") private var teamAvatarURL: String = ""
    @AppStorage("selectedEventCode") private var selectedEventCode: String = ""
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .tr }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(L10n.text(.teamPrefix, language: appLanguage)) \(teamNumber)")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.black)
                            Text(teamNickname.isEmpty ? "Overcharge" : teamNickname)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        TeamAvatarView(avatarURLString: teamAvatarURL, size: 42)
                    }

                    Text(selectedEventName.isEmpty ? L10n.text(.eventNotSelected, language: appLanguage) : selectedEventName)
                        .font(.headline)
                        .foregroundColor(.secondary)

                    liveMatchCard
                    liveActivityStatus

                    footer
                }
                .padding(20)
                .padding(.bottom, 88)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(L10n.text(.dashboard, language: appLanguage))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.text(.eventSelection, language: appLanguage)) {
                        selectedEventCode = ""
                    }
                }
            }
        }
    }

    private var liveMatchCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.text(.nextMatch, language: appLanguage))
                .font(.headline)
                .foregroundColor(.black)

            Text(L10n.text(.nextMatchPlaceholder, language: appLanguage))
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
            Text(L10n.text(.liveActivityReady, language: appLanguage))
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

    private var footer: some View {
        HStack {
            Spacer()
            Link(L10n.text(.poweredBy, language: appLanguage), destination: URL(string: "https://onurakyuz.com")!)
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.top, 8)
    }
}

#Preview {
    DashboardView()
}
