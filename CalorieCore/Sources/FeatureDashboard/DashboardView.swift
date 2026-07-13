import Charts
import DesignSystem
import Domain
import SwiftUI

/// Root-Screen: Rest-kcal groß, Makro-Balken + Tortendiagramm, heutige Einträge.
/// Kein TabBar – ein Screen-Prinzip. Kennt `FeatureSettings`/`FeatureLog` bewusst nicht
/// (Abhängigkeitsregel: Features → Domain + DesignSystem); beide Destinationen werden
/// vom Composition Root injiziert.
public struct DashboardView<SettingsDestination: View, LogSheetDestination: View>: View {
    @State private var viewModel: DashboardViewModel
    @State private var isShowingLogSheet = false
    private let settingsDestination: () -> SettingsDestination
    private let logSheetDestination: () -> LogSheetDestination

    public init(
        diaryRepository: any DiaryRepository,
        goalsRepository: any GoalsRepository,
        @ViewBuilder settingsDestination: @escaping () -> SettingsDestination,
        @ViewBuilder logSheetDestination: @escaping () -> LogSheetDestination
    ) {
        _viewModel = State(initialValue: DashboardViewModel(diaryRepository: diaryRepository, goalsRepository: goalsRepository))
        self.settingsDestination = settingsDestination
        self.logSheetDestination = logSheetDestination
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Heute")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            settingsDestination()
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    logButton
                }
                .sheet(isPresented: $isShowingLogSheet, onDismiss: reloadAfterLogSheet) {
                    logSheetDestination()
                }
                .task { await viewModel.load() }
        }
    }

    private func reloadAfterLogSheet() {
        Task { await viewModel.load() }
    }

    private var logButton: some View {
        Button {
            isShowingLogSheet = true
        } label: {
            Label("Erfassen", systemImage: "plus")
                .font(TypographyToken.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primary)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .empty:
            ContentUnavailableView("Keine Daten", systemImage: "flame")
        case let .error(message):
            ContentUnavailableView {
                Label("Fehler", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Erneut versuchen") { Task { await viewModel.load() } }
            }
        case let .loaded(totals):
            dashboard(for: totals)
        }
    }

    private func dashboard(for totals: DayTotals) -> some View {
        List {
            Section {
                remainingKcalSection(totals)
                macrosSection(totals)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            Section("Heutige Einträge") {
                if viewModel.todayEntries.isEmpty {
                    Text("Noch nichts erfasst.")
                        .font(TypographyToken.body)
                        .foregroundStyle(ColorToken.secondaryText)
                } else {
                    ForEach(viewModel.todayEntries) { entry in
                        entryRow(entry)
                            .swipeActions {
                                Button("Löschen", role: .destructive) {
                                    Task { await viewModel.delete(entryID: entry.id) }
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
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
    }

    private func remainingKcalSection(_ totals: DayTotals) -> some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                ProgressRing(progress: totals.goals.dailyKcal > 0 ? totals.kcal / Double(totals.goals.dailyKcal) : 0)
                    .frame(width: 200, height: 200)
                VStack {
                    Text("\(Int(totals.remainingKcal))")
                        .font(TypographyToken.remainingKcal)
                    Text("kcal übrig")
                        .font(TypographyToken.caption)
                        .foregroundStyle(ColorToken.secondaryText)
                }
            }
            Text("\(Int(totals.kcal)) konsumiert / \(totals.goals.dailyKcal) Ziel")
                .font(TypographyToken.body)
                .foregroundStyle(ColorToken.secondaryText)
        }
        .padding(.top, Spacing.lg)
    }

    private func macrosSection(_ totals: DayTotals) -> some View {
        VStack(spacing: Spacing.md) {
            Chart {
                SectorMark(angle: .value("Protein", max(totals.protein * 4, 0)), innerRadius: .ratio(0.6))
                    .foregroundStyle(.blue)
                SectorMark(angle: .value("Kohlenhydrate", max(totals.carbs * 4, 0)), innerRadius: .ratio(0.6))
                    .foregroundStyle(.orange)
                SectorMark(angle: .value("Fett", max(totals.fat * 9, 0)), innerRadius: .ratio(0.6))
                    .foregroundStyle(.pink)
            }
            .frame(height: 120)

            MacroBar(title: "Protein", currentGrams: totals.protein, targetGrams: Double(totals.goals.proteinGrams), tint: .blue)
            MacroBar(
                title: "Kohlenhydrate",
                currentGrams: totals.carbs,
                targetGrams: Double(totals.goals.carbsGrams),
                tint: .orange
            )
            MacroBar(title: "Fett", currentGrams: totals.fat, targetGrams: Double(totals.goals.fatGrams), tint: .pink)
        }
        .cardBackground()
    }
}
