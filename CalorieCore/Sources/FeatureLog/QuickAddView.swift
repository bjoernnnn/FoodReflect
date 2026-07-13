import DesignSystem
import Domain
import SwiftUI

/// Schnelleintrag-Fallback: Name + kcal (Makros optional) direkt als `DiaryEntry`,
/// ohne Umweg über einen Katalog-Eintrag. MVP-Pflicht, damit ein OFF-Miss keine
/// Sackgasse ist.
struct QuickAddView: View {
    let diaryRepository: any DiaryRepository
    let prefilledBarcode: String?
    let onSaved: () -> Void

    init(diaryRepository: any DiaryRepository, prefilledBarcode: String? = nil, onSaved: @escaping () -> Void) {
        self.diaryRepository = diaryRepository
        self.prefilledBarcode = prefilledBarcode
        self.onSaved = onSaved
    }

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var kcalText = ""
    @State private var proteinText = ""
    @State private var carbsText = ""
    @State private var fatText = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var isNameFocused: Bool

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && Double(kcalText) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                if let prefilledBarcode {
                    Section {
                        Label("Barcode \(prefilledBarcode) wurde nicht im Katalog gefunden.", systemImage: "barcode.viewfinder")
                            .font(TypographyToken.caption)
                            .foregroundStyle(ColorToken.secondaryText)
                    }
                }
                Section("Schnelleintrag") {
                    TextField("Name", text: $name).focused($isNameFocused)
                    HStack {
                        TextField("kcal", text: $kcalText).keyboardType(.numberPad)
                        Text("kcal")
                    }
                }
                Section("Makros (optional)") {
                    HStack {
                        TextField("Protein", text: $proteinText).keyboardType(.numberPad)
                        Text("g")
                    }
                    HStack {
                        TextField("Kohlenhydrate", text: $carbsText).keyboardType(.numberPad)
                        Text("g")
                    }
                    HStack {
                        TextField("Fett", text: $fatText).keyboardType(.numberPad)
                        Text("g")
                    }
                }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(ColorToken.warning)
                }
            }
            .navigationTitle("Schnelleintrag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { Task { await save() } }
                        .disabled(!canSave || isSaving)
                }
            }
            .onAppear { isNameFocused = true }
        }
    }

    private func save() async {
        guard let kcal = Double(kcalText) else { return }
        let now = Date()
        let entry = DiaryEntry(
            consumedAt: now,
            dayKey: DayKey.make(for: now),
            foodName: name.trimmingCharacters(in: .whitespaces),
            amountGrams: 0,
            kcal: kcal,
            protein: Double(proteinText) ?? 0,
            carbs: Double(carbsText) ?? 0,
            fat: Double(fatText) ?? 0
        )
        isSaving = true
        errorMessage = nil
        do {
            try await diaryRepository.save(entry)
            onSaved()
        } catch {
            errorMessage = "Speichern fehlgeschlagen. Bitte erneut versuchen."
        }
        isSaving = false
    }
}
