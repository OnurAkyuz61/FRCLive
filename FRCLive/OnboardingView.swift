import SwiftUI

struct OnboardingView: View {
    @AppStorage("teamNumber") private var storedTeamNumber: String = ""
    @State private var teamNumberInput: String = ""
    @State private var selectedLanguage: AppLanguage = .tr
    @State private var navigateToMain = false
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                logoSection
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

                languageSelector

                Spacer()

                Link("Powered by Onur Akyüz", destination: URL(string: "https://onurakyuz.com")!)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 32)
            .background(Color.white.ignoresSafeArea())
            .navigationDestination(isPresented: $navigateToMain) {
                MainNavigationView()
            }
        }
        .onAppear {
            teamNumberInput = storedTeamNumber
        }
    }

    private var logoSection: some View {
        VStack(spacing: 10) {
            // Ensure the "FIRST_Vertical_RGB" image asset exists in Assets.xcassets.
            Image("FIRST_Vertical_RGB")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
        }
        .frame(maxWidth: .infinity)
    }

    private var inputField: some View {
        HStack {
            TextField(
                AppStrings.text(.teamNumberPlaceholder, language: selectedLanguage),
                text: Binding(
                    get: { teamNumberInput },
                    set: { newValue in
                        teamNumberInput = newValue.filter(\.isNumber)
                    }
                ),
                prompt: Text(AppStrings.text(.teamNumberPlaceholder, language: selectedLanguage))
                    .foregroundColor(.white.opacity(0.42))
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
            let cleaned = teamNumberInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty else { return }

            storedTeamNumber = cleaned
            isFieldFocused = false
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                navigateToMain = true
            }
        } label: {
            Text(AppStrings.text(.continueButtonText, language: selectedLanguage))
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(red: 0.09, green: 0.19, blue: 0.36))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(teamNumberInput.isEmpty)
        .opacity(teamNumberInput.isEmpty ? 0.6 : 1)
        .animation(.easeInOut(duration: 0.2), value: teamNumberInput.isEmpty)
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

struct MainNavigationView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            Text("Main Navigation Placeholder")
                .foregroundStyle(.black)
                .font(.title2.weight(.semibold))
        }
    }
}

#Preview {
    OnboardingView()
}
