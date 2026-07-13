import DesignSystem
import Domain
import SwiftUI

/// Detailansicht eines Tagebucheintrags: volle Nährwerte, Menge editieren, löschen.
/// Erreichbar per Tap auf einen Eintrag im Dashboard.
struct EntryDetailView: View {
    @State private var viewModel: EntryDetailViewModel
    @State private var amountText: String
    @Environment(\.dismiss) private var dismiss
    private let onChange: () -> Void

    init(
        entry: DiaryEntry,
        diaryRepository: any DiaryRepository,
        widgetRefreshing: any WidgetRefreshing,
        onChange: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: EntryDetailViewModel(
            entry: entry, diaryRepository: diaryRepository, widgetRefreshing: widgetRefreshing
        ))
        _amountText = State(initialValue: String(Int(entry.amountGrams)))
        self.onChange = onChange
    }

    private var canUpdate: Bool {
        guard let value = Double(amountText) else { return false }
        return value > 0 && value != viewModel.entry.amountGrams
    }

    var body: some View {
        Form {
            Section(viewModel.entry.foodName) {
                HStack {
                    TextField("Menge", text: $amountText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("entryDetail.amountField")
                    Text("g").foregroundStyle(ColorToken.secondaryText)
                }
                Button("Menge aktualisieren") {
                    Task {
                        guard let value = Double(amountText) else { return }
                        if await viewModel.updateAmount(value) {
                            onChange()
                        }
                    }
                }
                .disabled(!canUpdate || viewModel.isSaving)
            }

            Section("Nährwerte") {
                LabeledContent("kcal", value: "\(Int(viewModel.entry.kcal))")
                LabeledContent("Protein", value: "\(Int(viewModel.entry.protein)) g")
                LabeledContent("Kohlenhydrate", value: "\(Int(viewModel.entry.carbs)) g")
                LabeledContent("Fett", value: "\(Int(viewModel.entry.fat)) g")
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(ColorToken.warning)
                }
            }

            Section {
                Button("Eintrag löschen", role: .destructive) {
                    Task {
                        if await viewModel.delete() {
                            onChange()
                            dismiss()
                        }
                    }
                }
                .accessibilityIdentifier("entryDetail.deleteButton")
            }
        }
        .navigationTitle("Eintrag")
        .navigationBarTitleDisplayMode(.inline)
    }
}
