import DesignSystem
import Domain
import SwiftUI

/// Eintragen oder Bearbeiten einer Gewichtsmessung: Zahl + Datum, Einheit kg.
/// Mit `existingEntry` startet das Formular vorbefüllt im Bearbeiten-Modus.
/// lb-Umschaltung ist bewusst Post-MVP (siehe TODO.md, Teil B Phase 5).
struct WeightEntrySheet: View {
    let existingEntry: WeightEntry?
    let initialCreatine: Bool
    let onSave: (Double, Date, Bool) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var weightText: String
    @State private var date: Date
    @State private var withCreatine: Bool
    @State private var isSaving = false
    @FocusState private var isWeightFocused: Bool

    init(
        existingEntry: WeightEntry? = nil,
        initialCreatine: Bool = false,
        onSave: @escaping (Double, Date, Bool) async -> Void
    ) {
        self.existingEntry = existingEntry
        self.initialCreatine = initialCreatine
        self.onSave = onSave
        _weightText = State(initialValue: existingEntry.map { String(format: "%.1f", $0.weightKg) } ?? "")
        _date = State(initialValue: existingEntry?.recordedAt ?? Date())
        _withCreatine = State(initialValue: existingEntry?.withCreatine ?? initialCreatine)
    }

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
                    Toggle("Mit Kreatin", isOn: $withCreatine)
                        .accessibilityIdentifier("weightEntry.creatineToggle")
                }
            }
            .navigationTitle(existingEntry == nil ? "Gewicht eintragen" : "Gewicht bearbeiten")
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
        await onSave(value, date, withCreatine)
        isSaving = false
    }
}
