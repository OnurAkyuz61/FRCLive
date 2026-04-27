import SwiftUI

struct OnboardingView: View {
    @AppStorage("frcTeamNumber") private var storedTeamNumber: String = ""
    @State private var teamNumberInput: String = ""
    @State private var selectedLanguage: AppLanguage = .en
    @State private var navigateToMain = false
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // User will insert the FIRST logo asset in this top placeholder space.
                    Color.clear
                        .frame(height: 150)

                    glassInteractionPanel

                    languageSelector

                    Spacer(minLength: 8)

                    Link("Powered by Onur Akyüz", destination: URL(string: "https://onurakyuz.com")!)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.bottom, 16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .navigationDestination(isPresented: $navigateToMain) {
                    MainNavigationView()
                }
            }
        }
        .onAppear {
            teamNumberInput = storedTeamNumber
        }
    }

    private var glassInteractionPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.cobalt.opacity(0.28),
                                    Color.amethyst.opacity(0.22),
                                    Color.emerald.opacity(0.24)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blur(radius: 18)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.50),
                                    .white.opacity(0.10),
                                    .white.opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.20), .clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .blendMode(.screen)
                        .padding(1)
                )
                .shadow(color: Color.cobalt.opacity(0.30), radius: 24, x: 0, y: 14)

            VStack(spacing: 18) {
                Text(AppStrings.text(.teamNumberTitle, language: selectedLanguage))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white.opacity(0.95))
                    .multilineTextAlignment(.center)

                glassTextField

                continueButton
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
        }
        .frame(maxWidth: 460)
        .frame(height: 280)
    }

    private var glassTextField: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.68),
                                    Color.amethyst.opacity(0.40),
                                    Color.cobalt.opacity(0.45)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.1
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.22), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blendMode(.screen)
                )

            TextField(
                AppStrings.text(.teamNumberPlaceholder, language: selectedLanguage),
                text: Binding(
                    get: { teamNumberInput },
                    set: { newValue in
                        teamNumberInput = newValue.filter(\.isNumber)
                    }
                )
            )
            .textInputAutocapitalization(.never)
            .keyboardType(.numberPad)
            .focused($isFieldFocused)
            .foregroundStyle(.white.opacity(0.95))
            .font(.title3.monospacedDigit().weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .frame(height: 54)
    }

    private var continueButton: some View {
        Button {
            let trimmed = teamNumberInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }

            storedTeamNumber = trimmed
            isFieldFocused = false
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                navigateToMain = true
            }
        } label: {
            Text(AppStrings.text(.continueButtonText, language: selectedLanguage))
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.cobalt.opacity(0.92), Color.amethyst.opacity(0.88), Color.emerald.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.cobalt.opacity(0.45), radius: 18, x: 0, y: 8)

                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(.white.opacity(0.42), lineWidth: 1)

                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.28), .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .blendMode(.screen)
                    }
                )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .scaleEffect(teamNumberInput.isEmpty ? 0.985 : 1.0)
        .opacity(teamNumberInput.isEmpty ? 0.72 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: teamNumberInput.isEmpty)
        .disabled(teamNumberInput.isEmpty)
    }

    private var languageSelector: some View {
        HStack(spacing: 14) {
            languageButton(for: .tr, label: "TR")
            languageButton(for: .en, label: "EN")
        }
        .padding(8)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.75))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func languageButton(for language: AppLanguage, label: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                selectedLanguage = language
            }
        } label: {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(selectedLanguage == language ? .white.opacity(0.24) : .white.opacity(0.08))
                        .overlay(
                            Circle().strokeBorder(.white.opacity(selectedLanguage == language ? 0.55 : 0.28), lineWidth: 1)
                        )
                )
                .shadow(
                    color: selectedLanguage == language ? Color.cobalt.opacity(0.35) : .clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .buttonStyle(.plain)
    }
}

private struct LiquidGlassBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color.cobalt.opacity(0.52),
                    Color.amethyst.opacity(0.45),
                    Color.emerald.opacity(0.36)
                ],
                startPoint: animate ? .topLeading : .bottomTrailing,
                endPoint: animate ? .bottomTrailing : .topLeading
            )

            RadialGradient(
                colors: [.white.opacity(0.15), .clear],
                center: animate ? .topLeading : .bottomTrailing,
                startRadius: 40,
                endRadius: 420
            )
            .blendMode(.screen)
            .blur(radius: 12)

            Ellipse()
                .fill(Color.cobalt.opacity(0.28))
                .frame(width: 340, height: 220)
                .offset(x: -100, y: -260)
                .blur(radius: 40)

            Ellipse()
                .fill(Color.amethyst.opacity(0.24))
                .frame(width: 380, height: 260)
                .offset(x: 130, y: -100)
                .blur(radius: 52)

            Ellipse()
                .fill(Color.emerald.opacity(0.22))
                .frame(width: 340, height: 280)
                .offset(x: 80, y: 250)
                .blur(radius: 46)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

private enum AppLanguage: String {
    case tr
    case en
}

private enum AppStringKey {
    case teamNumberTitle
    case teamNumberPlaceholder
    case continueButtonText
}

// Dummy localized strings provider for simple language switching.
private struct AppStrings {
    static func text(_ key: AppStringKey, language: AppLanguage) -> String {
        let tr: [AppStringKey: String] = [
            .teamNumberTitle: "FRC Takım Numaranızı Girin",
            .teamNumberPlaceholder: "örn. 6232",
            .continueButtonText: "Devam Et"
        ]
        let en: [AppStringKey: String] = [
            .teamNumberTitle: "Enter Your FRC Team Number",
            .teamNumberPlaceholder: "e.g., 6232",
            .continueButtonText: "Continue"
        ]

        switch language {
        case .tr:
            return tr[key] ?? ""
        case .en:
            return en[key] ?? ""
        }
    }
}

private extension Color {
    static let cobalt = Color(red: 0.16, green: 0.35, blue: 0.98)
    static let amethyst = Color(red: 0.56, green: 0.30, blue: 0.95)
    static let emerald = Color(red: 0.05, green: 0.78, blue: 0.50)
}

/// Placeholder destination view until app navigation is wired.
struct MainNavigationView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Main Navigation Placeholder")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    OnboardingView()
}
