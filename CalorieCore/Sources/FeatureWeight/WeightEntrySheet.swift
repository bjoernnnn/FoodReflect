import DesignSystem
import SwiftUI

/// Eintragen einer neuen Gewichtsmessung: Zahl + Datum, Einheit kg.
/// lb-Umschaltung ist bewusst Post-MVP (siehe todo2.md Phase 5).
struct WeightEntrySheet: View {
    let onSave: (Double, Date) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var weightText = ""
    @State private var date = Date()
    @State private var isSaving = false
    @FocusState private var isWeightFocused: Bool

    private var canSave: Bool {
        guard let value = Double(weightText.replacingOccurrences(of: ",", with: ".")) else { return false }
        return value > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Gewicht") {
                    HStack {
                        TextField("Gewicht", text: $weightText)
                            .keyboardType(.decimalPad)
                            .focused($isWeightFocused)
                            .accessibilityIdentifier("weightEntry.weightField")
                        Text("kg")
                            .foregroundStyle(ColorToken.secondaryText)
                    }
                    DatePicker("Datum", selection: $date, in: ...Date(), displayedComponents: .date)
                }
            }
            .navigationTitle("Gewicht eintragen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { Task { await save() } }
                        .disabled(!canSave || isSaving)
                        .accessibilityIdentifier("weightEntry.saveButton")
                }
            }
            .onAppear { isWeightFocused = true }
        }
    }

    private func save() async {
        guard let value = Double(weightText.replacingOccurrences(of: ",", with: ".")) else { return }
        isSaving = true
        await onSave(value, date)
        isSaving = false
    }
}
