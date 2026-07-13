import DesignSystem
import Domain
import SwiftUI

/// Einmaliger Onboarding-Screen: ein Eingabefeld (Tagesziel kcal), Makros werden
/// automatisch vorgeschlagen (30/40/30) und sind später in den Einstellungen anpassbar.
public struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel
    @FocusState private var isInputFocused: Bool
    private let onComplete: () -> Void

    public init(goalsRepository: any GoalsRepository, onComplete: @escaping () -> Void) {
        _viewModel = State(initialValue: OnboardingViewModel(goalsRepository: goalsRepository))
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            VStack(spacing: Spacing.sm) {
                Text("Willkommen 👋")
                    .font(TypographyToken.title)
                Text("Wie viele Kalorien willst du täglich zu dir nehmen?")
                    .font(TypographyToken.body)
                    .foregroundStyle(ColorToken.secondaryText)
                    .multilineTextAlignment(.center)
            }

            TextField("Tagesziel", text: $viewModel.dailyKcalInput)
                .keyboardType(.numberPad)
                .focused($isInputFocused)
                .font(TypographyToken.remainingKcal)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 200)

            Text("kcal / Tag")
                .font(TypographyToken.caption)
                .foregroundStyle(ColorToken.secondaryText)

            macroPreview
                .cardBackground()
                .padding(.horizontal, Spacing.lg)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(TypographyToken.caption)
                    .foregroundStyle(ColorToken.warning)
            }

            Spacer()

            Button {
                Task {
                    await viewModel.confirm()
                    if viewModel.didCompleteOnboarding {
                        onComplete()
                    }
                }
            } label: {
                if viewModel.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Los geht's")
                }
            }
            .buttonStyle(.primary)
            .disabled(!viewModel.canConfirm || viewModel.isSaving)
            .padding(.horizontal, Spacing.lg)
        }
        .padding(.vertical, Spacing.xl)
        .onAppear { isInputFocused = true }
    }

    private var macroPreview: some View {
        let goals = viewModel.suggestedGoals
        return VStack(spacing: Spacing.sm) {
            Text("Automatischer Vorschlag")
                .font(TypographyToken.caption)
                .foregroundStyle(ColorToken.secondaryText)
            HStack {
                macroPreviewColumn(label: "Protein", grams: goals.proteinGrams)
                macroPreviewColumn(label: "Kohlenhydrate", grams: goals.carbsGrams)
                macroPreviewColumn(label: "Fett", grams: goals.fatGrams)
            }
        }
    }

    private func macroPreviewColumn(label: String, grams: Int) -> some View {
        VStack(spacing: Spacing.xs) {
            Text("\(grams)g")
                .font(TypographyToken.headline)
            Text(label)
                .font(TypographyToken.caption)
                .foregroundStyle(ColorToken.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}
