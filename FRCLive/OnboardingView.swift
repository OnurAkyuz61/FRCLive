import SwiftUI

struct OnboardingView: View {
    @AppStorage("teamNumber") private var storedTeamNumber: String = ""
    @State private var teamNumberInput: String = ""
    @State private var selectedLanguage: AppLanguage = .tr
    @State private var navigateToMain = false
    @State private var animateCircuit = false
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                EngineeringBackground()
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    logoSection
                        .padding(.top, 20)

                    engineeringPanel

                    languageSelector

                    Spacer(minLength: 8)

                    Link("Powered by Onur Akyüz", destination: URL(string: "https://onurakyuz.com")!)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.88))
                        .padding(.bottom, 14)
                }
                .padding(.horizontal, 24)
                .navigationDestination(isPresented: $navigateToMain) {
                    MainNavigationView()
                }
            }
        }
        .onAppear {
            teamNumberInput = storedTeamNumber
            withAnimation(.linear(duration: 2.3).repeatForever(autoreverses: false)) {
                animateCircuit = true
            }
        }
    }

    private var logoSection: some View {
        VStack(spacing: 10) {
            // Ensure the "FIRST_Vertical_RGB" image asset exists in Assets.xcassets.
            Image("FIRST_Vertical_RGB")
                .resizable()
                .scaledToFit()
                .frame(width: 126, height: 126)
                .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
        }
        .frame(maxWidth: .infinity)
    }

    private var engineeringPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.78))
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.14), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.26), lineWidth: 0.9)
                )
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: 1)
                        .padding(.horizontal, 1)
                }
                .shadow(color: .black.opacity(0.45), radius: 20, x: 0, y: 14)

            CarbonPlate()
                .mask(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .inset(by: 0.5)
                )
                .opacity(0.22)

            EdgeCircuitOverlay(progress: animateCircuit ? 1 : 0)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(spacing: 16) {
                Text(AppStrings.text(.teamNumberTitle, language: selectedLanguage))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.95))

                digitalTextField
                continueButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .frame(maxWidth: 470)
        .frame(height: 272)
    }

    private var digitalTextField: some View {
        HStack(spacing: 10) {
            Image(systemName: "number.square")
                .foregroundStyle(Color.cobalt.opacity(0.88))
                .font(.system(size: 19, weight: .semibold))

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
            .font(.system(.title3, design: .monospaced).weight(.medium))
            .foregroundStyle(.white)
            .tint(.emerald)
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.30))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.55), .white.opacity(0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.9
                        )
                )
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.emerald.opacity(0.45))
                        .frame(height: 1)
                }
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
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    ZStack {
                        CarbonPlate()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.cobalt, Color.amethyst, Color.emerald],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1.35
                            )
                            .hueRotation(.degrees(animateCircuit ? 25 : -12))

                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.20), .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                )
                .shadow(color: Color.cobalt.opacity(0.35), radius: 12, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(teamNumberInput.isEmpty)
        .opacity(teamNumberInput.isEmpty ? 0.64 : 1)
        .scaleEffect(teamNumberInput.isEmpty ? 0.99 : 1)
        .animation(.easeInOut(duration: 0.2), value: teamNumberInput.isEmpty)
    }

    private var languageSelector: some View {
        HStack(spacing: 12) {
            languageButton(language: .tr, label: "TR")
            languageButton(language: .en, label: "EN")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.7))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(.white.opacity(0.25), lineWidth: 0.8)
                )
        )
    }

    private func languageButton(language: AppLanguage, label: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedLanguage = language
            }
        } label: {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(selectedLanguage == language ? Color.white.opacity(0.18) : Color.white.opacity(0.06))
                        .overlay(
                            Circle()
                                .strokeBorder(selectedLanguage == language ? Color.emerald.opacity(0.72) : Color.white.opacity(0.22), lineWidth: 0.9)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

private struct EngineeringBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.05, blue: 0.10),
                    Color(red: 0.05, green: 0.07, blue: 0.14),
                    Color(red: 0.06, green: 0.05, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            CircuitGrid()
                .stroke(Color.white.opacity(0.06), lineWidth: 0.6)
                .blendMode(.plusLighter)

            RadialGradient(
                colors: [Color.cobalt.opacity(0.20), .clear],
                center: .topLeading,
                startRadius: 30,
                endRadius: 430
            )
            RadialGradient(
                colors: [Color.amethyst.opacity(0.16), .clear],
                center: .center,
                startRadius: 40,
                endRadius: 500
            )
            RadialGradient(
                colors: [Color.emerald.opacity(0.14), .clear],
                center: .bottomTrailing,
                startRadius: 30,
                endRadius: 430
            )
        }
    }
}

private struct CircuitGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let gap: CGFloat = 34

        var x: CGFloat = 0
        while x <= rect.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
            x += gap
        }

        var y: CGFloat = 0
        while y <= rect.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
            y += gap
        }

        return path
    }
}

private struct EdgeCircuitOverlay: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let rect = geometry.frame(in: .local)
            let frame = RoundedRectangle(cornerRadius: 20, style: .continuous)

            frame
                .trim(from: 0, to: 1)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)

            frame
                .trim(from: progress - 0.18, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [Color.cobalt, Color.amethyst, Color.emerald],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                )
                .shadow(color: Color.emerald.opacity(0.45), radius: 5)

            Path { path in
                path.move(to: CGPoint(x: rect.minX + 24, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.minX + 58, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.minX + 58, y: rect.midY + 24))
                path.addLine(to: CGPoint(x: rect.minX + 100, y: rect.midY + 24))
                path.move(to: CGPoint(x: rect.maxX - 24, y: rect.midY - 18))
                path.addLine(to: CGPoint(x: rect.maxX - 78, y: rect.midY - 18))
                path.addLine(to: CGPoint(x: rect.maxX - 78, y: rect.midY + 8))
                path.addLine(to: CGPoint(x: rect.maxX - 118, y: rect.midY + 8))
            }
            .stroke(Color.white.opacity(0.14), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        }
        .allowsHitTesting(false)
    }
}

private struct CarbonPlate: View {
    var body: some View {
        Canvas { context, size in
            let cell: CGFloat = 8
            var row: Int = 0
            var y: CGFloat = 0

            while y < size.height {
                var col: Int = 0
                var x: CGFloat = 0
                while x < size.width {
                    let isDark = (row + col).isMultiple(of: 2)
                    let color = isDark
                        ? Color.black.opacity(0.36)
                        : Color.white.opacity(0.07)
                    let rect = CGRect(x: x, y: y, width: cell, height: cell)
                    context.fill(Path(rect), with: .color(color))
                    col += 1
                    x += cell
                }
                row += 1
                y += cell
            }
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

private extension Color {
    static let cobalt = Color(red: 0.16, green: 0.35, blue: 0.98)
    static let amethyst = Color(red: 0.56, green: 0.30, blue: 0.95)
    static let emerald = Color(red: 0.05, green: 0.78, blue: 0.50)
}

struct MainNavigationView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Main Navigation Placeholder")
                .foregroundStyle(.white)
                .font(.title2.weight(.semibold))
        }
    }
}

#Preview {
    OnboardingView()
}
