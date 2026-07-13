import FeatureSettings
import SwiftUI

/// Weiche zwischen Onboarding und der Tab-Navigation, anhand ob bereits Ziele gespeichert sind.
struct RootView: View {
    @Environment(AppContainer.self) private var container
    @State private var hasCompletedOnboarding: Bool?

    var body: some View {
        Group {
            switch hasCompletedOnboarding {
            case nil:
                ProgressView()
            case false:
                OnboardingView(goalsRepository: container.goalsRepository) {
                    hasCompletedOnboarding = true
                }
            case true:
                RootTabView()
            }
        }
        .task {
            guard hasCompletedOnboarding == nil else { return }
            let goals = try? await container.goalsRepository.currentGoals()
            hasCompletedOnboarding = goals != nil
        }
    }
}
