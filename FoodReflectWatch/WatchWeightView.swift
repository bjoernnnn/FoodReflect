import Foundation
import SwiftUI
import Sync

/// Gewichtseingabe per Digital Crown (±0,1 kg) inkl. Kreatin-Toggle. Speichern sendet ein
/// `logWeight`-Event ans iPhone und aktualisiert den lokalen Snapshot optimistisch.
struct WatchWeightView: View {
    let sync: WatchSyncService

    @Environment(\.dismiss) private var dismiss
    @State private var weight: Double
    @State private var creatine: Bool
    @State private var didSave = false
    @FocusState private var crownFocused: Bool

    init(sync: WatchSyncService) {
        self.sync = sync
        _weight = State(initialValue: sync.snapshot.latestWeightKg ?? 80.0)
        _creatine = State(initialValue: sync.snapshot.latestCreatine)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(formattedWeight)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .contentTransition(.numericText(value: weight))
                .focusable()
                .focused($crownFocused)
                .digitalCrownRotation(
                    $weight,
                    from: 30,
                    through: 300,
                    by: 0.1,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
            Text("kg")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Toggle("Kreatin", isOn: $creatine)
                .font(.footnote)
                .tint(WatchTheme.accent)

            Button(action: save) {
                Label("Speichern", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .tint(WatchTheme.accent)
        }
        .padding(.horizontal)
        .navigationTitle("Gewicht")
        .onAppear { crownFocused = true }
        .sensoryFeedback(.success, trigger: didSave)
    }

    private var formattedWeight: String {
        String(format: "%.1f", weight).replacingOccurrences(of: ".", with: ",")
    }

    private func save() {
        let event = WatchEvent(
            id: UUID(),
            kind: .logWeight(weightKg: weight, creatine: creatine),
            occurredAt: Date()
        )
        sync.send(event)
        sync.applyOptimistic { snapshot in
            snapshot.latestWeightKg = weight
            snapshot.latestCreatine = creatine
        }
        didSave = true
        dismiss()
    }
}
