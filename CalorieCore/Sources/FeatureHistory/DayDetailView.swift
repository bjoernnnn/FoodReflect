import DesignSystem
import Domain
import SwiftUI

/// Tages-Detail: alle Einträge des Tages, Makro-Aufschlüsselung, Zielerreichung.
/// Erreichbar per Tap auf einen Tag im Verlauf.
struct DayDetailView: View {
    @State private var viewModel: DayDetailViewModel

    init(dayKey: String, diaryRepository: any DiaryRepository, goalsRepository: any GoalsRepository) {
        _viewModel = State(initialValue: DayDetailViewModel(
            dayKey: dayKey, diaryRepository: diaryRepository, goalsRepository: goalsRepository
        ))
    }

    var body: some View {
        content
            .navigationTitle(formattedDay(viewModel.dayKey))
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .empty:
            ContentUnavailableView("Keine Einträge an diesem Tag", systemImage: "tray")
        case let .error(message):
            ContentUnavailableView {
                Label("Fehler", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Erneut versuchen") { Task { await viewModel.load() } }
            }
        case let .loaded(totals):
            List {
                Section {
                    macroBreakdown(totals)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                Section("Einträge") {
                    ForEach(viewModel.entries) { entry in
                        entryRow(entry)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func macroBreakdown(_ totals: DayTotals) -> some View {
        VStack(spacing: Spacing.md) {
            Text("\(Int(totals.kcal)) / \(totals.goals.dailyKcal) kcal")
                .font(TypographyToken.title)
            MacroBar(
                title: "Protein", currentGrams: totals.protein, targetGrams: Double(totals.goals.proteinGrams),
                tint: ColorToken.proteinColor
            )
            MacroBar(
                title: "Kohlenhydrate", currentGrams: totals.carbs, targetGrams: Double(totals.goals.carbsGrams),
                tint: ColorToken.carbsColor
            )
            MacroBar(
                title: "Fett", currentGrams: totals.fat, targetGrams: Double(totals.goals.fatGrams),
                tint: ColorToken.fatColor
            )
        }
        .cardBackground()
    }

    private func entryRow(_ entry: DiaryEntry) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(entry.foodName).font(TypographyToken.body)
                Text("\(Int(entry.amountGrams)) g")
                    .font(TypographyToken.caption)
                    .foregroundStyle(ColorToken.secondaryText)
            }
            Spacer()
            Text("\(Int(entry.kcal)) kcal").font(TypographyToken.body)
        }
        .accessibilityElement(children: .combine)
    }

    private func formattedDay(_ dayKey: String) -> String {
        let parts = dayKey.split(separator: "-")
        guard parts.count == 3 else { return dayKey }
        return "\(parts[2]).\(parts[1]).\(parts[0])"
    }
}
