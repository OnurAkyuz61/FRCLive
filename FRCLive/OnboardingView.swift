import SwiftUI
import WebKit

struct OnboardingView: View {
    @AppStorage("teamNumber") private var storedTeamNumber: String = ""
    @AppStorage(TBAAPIClient.tbaAuthKeyStorageKey) private var storedTBAKey: String = ""
    @State private var teamNumberInput: String = ""
    @State private var tbaKeyInput: String = ""
    @State private var tbaKeyStatusMessage: String?
    @State private var isTBAKeyConfirmed = false
    @State private var selectedLanguage: AppLanguage = .tr
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isFieldFocused: Bool
    private let maxTeamNumberLength = 5

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                rebuiltGifSection
                    .padding(.top, 48)
                    .padding(.bottom, 28)

                Text(AppStrings.text(.teamNumberTitle, language: selectedLanguage))
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)

                inputField
                    .padding(.bottom, 14)

                continueButton
                    .padding(.bottom, 20)

                tbaKeySection
                    .padding(.bottom, 16)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 12)
                }

                languageSelector

                Spacer()

                firstLogoBottomSection
                    .padding(.bottom, 8)

                Link("Powered by Onur Akyüz", destination: URL(string: "https://onurakyuz.com")!)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 32)
            .background(Color.white.ignoresSafeArea())
        }
        .onAppear {
            let clamped = String(storedTeamNumber.prefix(maxTeamNumberLength))
            if storedTeamNumber != clamped {
                storedTeamNumber = clamped
            }
            teamNumberInput = clamped
            tbaKeyInput = storedTBAKey
            if !storedTBAKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                isTBAKeyConfirmed = true
                tbaKeyStatusMessage = "Onaylandı"
            }
        }
    }

    private var rebuiltGifSection: some View {
        VStack(spacing: 10) {
            // Put "rebuilt.gif" under FRCLive/ and ensure it's included in app target.
            GIFView(gifName: "rebuilt")
                .frame(width: 230, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }

    private var firstLogoBottomSection: some View {
        Image("FIRST_Vertical_RGB")
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 90)
            .opacity(0.95)
    }

    private var inputField: some View {
        HStack {
            TextField(
                AppStrings.text(.teamNumberPlaceholder, language: selectedLanguage),
                text: Binding(
                    get: { teamNumberInput },
                    set: { newValue in
                        let digitsOnly = newValue.filter(\.isNumber)
                        teamNumberInput = String(digitsOnly.prefix(maxTeamNumberLength))
                    }
                ),
                prompt: Text(AppStrings.text(.teamNumberPlaceholder, language: selectedLanguage))
                    .foregroundColor(.gray)
            )
            .keyboardType(.numberPad)
            .textInputAutocapitalization(.never)
            .focused($isFieldFocused)
            .font(.body)
            .foregroundColor(.black)
            .tint(.black)
        }
        .padding(.horizontal, 12)
        .frame(height: 54)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.gray.opacity(0.7), lineWidth: 1)
        )
    }

    private var continueButton: some View {
        Button {
            Task {
                await validateAndContinue()
            }
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(AppStrings.text(.continueButtonText, language: selectedLanguage))
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color(red: 0.09, green: 0.19, blue: 0.36))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(teamNumberInput.isEmpty || isLoading || !isTBAKeyConfirmed)
        .opacity((teamNumberInput.isEmpty || isLoading || !isTBAKeyConfirmed) ? 0.6 : 1)
        .animation(.easeInOut(duration: 0.2), value: teamNumberInput.isEmpty || isLoading || !isTBAKeyConfirmed)
    }

    private var tbaKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TBA API Key")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.black)

            if isTBAKeyConfirmed {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("TBA Key Onaylandı")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.green)
                    Spacer()
                    Button("Kaldır") {
                        storedTBAKey = ""
                        tbaKeyInput = ""
                        isTBAKeyConfirmed = false
                        tbaKeyStatusMessage = nil
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.green.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.green.opacity(0.30), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                TextField(
                    "TBA key girin",
                    text: $tbaKeyInput,
                    prompt: Text("TBA key girin").foregroundColor(.gray)
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .font(.footnote.monospaced())
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                )

                HStack(spacing: 10) {
                    Button("Onayla") {
                        let cleaned = tbaKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !cleaned.isEmpty else { return }
                        storedTBAKey = cleaned
                        isTBAKeyConfirmed = true
                        tbaKeyStatusMessage = nil
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.09, green: 0.19, blue: 0.36))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
    }

    private var languageSelector: some View {
        HStack(spacing: 12) {
            languageTextButton(language: .tr, label: "TR")
            Text("|")
                .foregroundColor(.gray)
            languageTextButton(language: .en, label: "EN")
        }
    }

    private func languageTextButton(language: AppLanguage, label: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedLanguage = language
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(selectedLanguage == language ? .black : .gray)
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func validateAndContinue() async {
        let cleaned = teamNumberInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        guard isTBAKeyConfirmed else {
            errorMessage = "Devam etmek için önce TBA API Key onaylanmalı."
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await FRCService.shared.validateTeam(teamNumber: cleaned)
            storedTeamNumber = cleaned
            isFieldFocused = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum AppLanguage {
    case tr
    case en
}

private enum AppStringKey {
    case teamNumberTitle
    case teamNumberPlaceholder
    case continueButtonText
}

private struct AppStrings {
    static func text(_ key: AppStringKey, language: AppLanguage) -> String {
        let tr: [AppStringKey: String] = [
            .teamNumberTitle: "FRC Takım Numaranız",
            .teamNumberPlaceholder: "örn. 6232",
            .continueButtonText: "Devam Et"
        ]
        let en: [AppStringKey: String] = [
            .teamNumberTitle: "Your FRC Team Number",
            .teamNumberPlaceholder: "e.g., 6232",
            .continueButtonText: "Continue"
        ]
        return language == .tr ? (tr[key] ?? "") : (en[key] ?? "")
    }
}

#Preview {
    OnboardingView()
}

private struct GIFView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = Bundle.main.url(forResource: gifName, withExtension: "gif") else {
            return
        }
        let html = """
        <html>
        <head><meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0"/></head>
        <body style="margin:0; background:transparent; overflow:hidden;">
            <img src="\(url.lastPathComponent)" style="width:100%; height:100%; object-fit:contain;" />
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
    }
}
