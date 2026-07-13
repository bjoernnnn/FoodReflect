import SwiftUI

/// Weiche zwischen Onboarding und Dashboard. Die tatsächliche Verzweigung
/// (anhand gespeicherter Ziele) folgt in Phase 4.
struct RootView: View {
    var body: some View {
        ContentUnavailableView(
            "KalorienTracker",
            systemImage: "flame",
            description: Text("Projektgerüst – Onboarding/Dashboard folgen in Phase 4.")
        )
    }
}

#Preview {
    RootView()
}
