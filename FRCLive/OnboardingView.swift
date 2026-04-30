import SwiftUI
import WebKit

struct OnboardingView: View {
    @AppStorage("teamNumber") private var storedTeamNumber: String = ""
    @State private var teamNumberInput: String = ""
    @State private var tbaKeyInput: String = ""
    @State private var tbaKeyStatusMessage: String?
    @State private var isTBAKeyConfirmed = false
    @State private var nexusKeyInput: String = ""
    @State private var isNexusKeyConfirmed = false
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.tr.rawValue
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @FocusState private var isFieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    private let maxTeamNumberLength = 5
    private var appLanguage: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .tr }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                rebuiltGifSection
                    .padding(.top, 48)
                    .padding(.bottom, 28)

                Text(L10n.text(.teamNumberTitle, language: appLanguage))
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)

                inputField
                    .padding(.bottom, 14)

                continueButton
                    .padding(.bottom, 20)

                tbaKeySection
                    .padding(.bottom, 16)

                nexusKeySection
                    .padding(.bottom, 16)

                languageSelector

                Spacer()

                firstLogoBottomSection
                    .padding(.bottom, 8)

                Link(L10n.text(.poweredBy, language: appLanguage), destination: URL(string: "https://onurakyuz.com")!)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 32)
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
        }
        .onAppear {
            let clamped = String(storedTeamNumber.prefix(maxTeamNumberLength))
            if storedTeamNumber != clamped {
                storedTeamNumber = clamped
            }
            teamNumberInput = clamped
            let persistedKey = TBAAPIClient.shared.persistedTBAAuthKey()
            tbaKeyInput = persistedKey
            if !persistedKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                isTBAKeyConfirmed = true
                tbaKeyStatusMessage = "Onaylandı"
            }

            let persistedNexusKey = NexusAPIClient.shared.persistedNexusApiKey()
            nexusKeyInput = persistedNexusKey
            if !persistedNexusKey.isEmpty {
                isNexusKeyConfirmed = true
            }
        }
        .alert(
            L10n.text(.alertWarningTitle, language: appLanguage),
            isPresented: $showErrorAlert,
            actions: {
                Button(L10n.text(.alertOk, language: appLanguage), role: .cancel) {}
            },
            message: {
                Text(errorMessage ?? L10n.text(.teamValidationFailed, language: appLanguage))
            }
        )
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
        Image(colorScheme == .dark ? "FRC_White" : "FRC")
            .resizable()
            .scaledToFit()
            .frame(width: 170, height: 120)
            .opacity(0.95)
    }

    private var inputField: some View {
        HStack {
            TextField(
                L10n.text(.teamNumberPlaceholder, language: appLanguage),
                text: Binding(
                    get: { teamNumberInput },
                    set: { newValue in
                        let digitsOnly = newValue.filter(\.isNumber)
                        teamNumberInput = String(digitsOnly.prefix(maxTeamNumberLength))
                    }
                ),
                prompt: Text(L10n.text(.teamNumberPlaceholder, language: appLanguage))
                    .foregroundColor(.gray)
            )
            .keyboardType(.numberPad)
            .textInputAutocapitalization(.never)
            .focused($isFieldFocused)
            .font(.body)
            .foregroundColor(.primary)
            .tint(.primary)
        }
        .padding(.horizontal, 12)
        .frame(height: 54)
        .background(Color(UIColor.secondarySystemBackground))
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
                    Text(L10n.text(.continueButton, language: appLanguage))
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
        .disabled(teamNumberInput.isEmpty || isLoading || !isTBAKeyConfirmed || !isNexusKeyConfirmed)
        .opacity((teamNumberInput.isEmpty || isLoading || !isTBAKeyConfirmed || !isNexusKeyConfirmed) ? 0.6 : 1)
        .animation(.easeInOut(duration: 0.2), value: teamNumberInput.isEmpty || isLoading || !isTBAKeyConfirmed || !isNexusKeyConfirmed)
    }

    private var tbaKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text(.tbaApiKey, language: appLanguage))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            if isTBAKeyConfirmed {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text(L10n.text(.tbaKeyConfirmed, language: appLanguage))
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.green)
                    Spacer()
                    Button(L10n.text(.remove, language: appLanguage)) {
                        TBAAPIClient.shared.clearTBAAuthKey()
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
                    L10n.text(.enterTbaKey, language: appLanguage),
                    text: $tbaKeyInput,
                    prompt: Text(L10n.text(.enterTbaKey, language: appLanguage)).foregroundColor(.gray)
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .font(.footnote.monospaced())
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                )

                HStack(spacing: 10) {
                    Button(L10n.text(.confirm, language: appLanguage)) {
                        let cleaned = tbaKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !cleaned.isEmpty else { return }
                        TBAAPIClient.shared.saveTBAAuthKey(cleaned)
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

    private var nexusKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text(.nexusApiKey, language: appLanguage))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            if isNexusKeyConfirmed {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text(L10n.text(.nexusKeyConfirmed, language: appLanguage))
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.green)
                    Spacer()
                    Button(L10n.text(.remove, language: appLanguage)) {
                        NexusAPIClient.shared.clearNexusApiKey()
                        nexusKeyInput = ""
                        isNexusKeyConfirmed = false
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
                    L10n.text(.enterNexusKey, language: appLanguage),
                    text: $nexusKeyInput,
                    prompt: Text(L10n.text(.enterNexusKey, language: appLanguage)).foregroundColor(.gray)
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .font(.footnote.monospaced())
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                )

                HStack(spacing: 10) {
                    Button(L10n.text(.confirm, language: appLanguage)) {
                        let cleaned = nexusKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !cleaned.isEmpty else { return }
                        NexusAPIClient.shared.saveNexusApiKey(cleaned)
                        isNexusKeyConfirmed = true
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
                appLanguageRaw = language.rawValue
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(appLanguage == language ? .primary : .gray)
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func validateAndContinue() async {
        let cleaned = teamNumberInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        guard isTBAKeyConfirmed else {
            errorMessage = L10n.text(.mustConfirmTba, language: appLanguage)
            showErrorAlert = true
            return
        }
        guard isNexusKeyConfirmed else {
            errorMessage = L10n.text(.mustConfirmNexus, language: appLanguage)
            showErrorAlert = true
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await TBAAPIClient.shared.fetchTeamProfile(teamNumber: cleaned)
            storedTeamNumber = cleaned
            isFieldFocused = false
        } catch {
            if let tbaError = error as? TBAAPIClientError {
                switch tbaError {
                case .unauthorized:
                    errorMessage = L10n.text(.tbaKeyInvalid, language: appLanguage)
                case .invalidTeam, .invalidRequest, .failedToLoadEvents:
                    errorMessage = L10n.text(.invalidTeamOrEvents, language: appLanguage)
                }
            } else if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                errorMessage = appLanguage == .tr ? "Internet baglantisi bulunamadi." : "No internet connection."
            } else {
                errorMessage = L10n.text(.teamValidationFailed, language: appLanguage)
            }
            showErrorAlert = true
        }
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
