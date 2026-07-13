import Charts
import DesignSystem
import Domain
import SwiftUI

/// Root-Screen: Rest-kcal groß, Makro-Balken + Tortendiagramm, heutige Einträge.
/// Lebt als Tab in der `RootTabView`. Kennt `FeatureLog` bewusst nicht (Abhängigkeitsregel:
/// Features → Domain + DesignSystem); die Log-Sheet-Destination wird vom Composition Root injiziert.
public struct DashboardView<LogSheetDestination: View>: View {
    @State private var viewModel: DashboardViewModel
    @State private var isShowingLogSheet = false
    @Environment(\.scenePhase) private var scenePhase
    /// `TypographyToken.remainingKcal` ist eine feste Größe; hier per `@ScaledMetric`
    /// überschrieben, damit die eine Zahl, die zählt, auf Dynamic-Type-Änderungen reagiert.
    @ScaledMetric(relativeTo: .largeTitle) private var remainingKcalFontSize: CGFloat = 56
    private let logSheetDestination: () -> LogSheetDestination

    public init(
        diaryRepository: any DiaryRepository,
        goalsRepository: any GoalsRepository,
        widgetRefreshing: any WidgetRefreshing,
        @ViewBuilder logSheetDestination: @escaping () -> LogSheetDestination
    ) {
        _viewModel = State(initialValue: DashboardViewModel(
            diaryRepository: diaryRepository, goalsRepository: goalsRepository, widgetRefreshing: widgetRefreshing
        ))
        self.logSheetDestination = logSheetDestination
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Heute")
                .safeAreaInset(edge: .bottom) {
                    logButton
                }
                .sheet(isPresented: $isShowingLogSheet, onDismiss: reloadAfterLogSheet) {
                    logSheetDestination()
                }
                .task { await viewModel.load() }
                // Deckt Mitternachts-/Zeitzonenwechsel ab: dayKey wird bei jeder
                // Rückkehr in den Vordergrund frisch berechnet statt gecacht zu bleiben.
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task { await viewModel.load() }
                }
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
        .accessibilityIdentifier("dashboard.logButton")
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
                if let weekStats = viewModel.weekStats, !weekStats.days.isEmpty {
                    weekCard(weekStats)
                }
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
        .accessibilityElement(children: .combine)
    }

    private func remainingKcalSection(_ totals: DayTotals) -> some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                ProgressRing(progress: totals.goals.dailyKcal > 0 ? totals.kcal / Double(totals.goals.dailyKcal) : 0)
                    .frame(width: 200, height: 200)
                    .accessibilityHidden(true)
                VStack {
                    Text("\(Int(totals.remainingKcal))")
                        .font(.system(size: remainingKcalFontSize, weight: .bold, design: .rounded))
                    Text("kcal übrig")
                        .font(TypographyToken.caption)
                        .foregroundStyle(ColorToken.secondaryText)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("dashboard.remainingKcal")
            }
            Text("\(Int(totals.kcal)) konsumiert / \(totals.goals.dailyKcal) Ziel")
                .font(TypographyToken.body)
                .foregroundStyle(ColorToken.secondaryText)
                .accessibilityIdentifier("dashboard.consumedSummary")
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
            .accessibilityLabel("Makro-Verteilung")
            .accessibilityValue(
                "\(Int(totals.protein))g Protein, \(Int(totals.carbs))g Kohlenhydrate, \(Int(totals.fat))g Fett"
            )

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

    private func weekCard(_ weekStats: WeekStats) -> some View {
        let goal = weekStats.days.last?.goals.dailyKcal ?? 0
        let delta = weekStats.deltaFromGoal
        let deltaDirection = delta <= 0 ? "unter" : "über"

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Diese Woche")
                .font(TypographyToken.headline)

            Chart {
                ForEach(weekStats.days, id: \.dayKey) { day in
                    BarMark(x: .value("Tag", day.dayKey), y: .value("kcal", day.kcal))
                        .foregroundStyle(ColorToken.accent)
                        .cornerRadius(4)
                }
                if goal > 0 {
                    RuleMark(y: .value("Ziel", goal))
                        .foregroundStyle(ColorToken.secondaryText)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
            }
            .chartXAxis(.hidden)
            .frame(height: 100)
            .accessibilityLabel("Wochenverlauf")
            .accessibilityValue(
                "Durchschnitt \(Int(weekStats.averageKcal)) Kilokalorien pro Tag, \(Int(abs(delta))) \(deltaDirection) Ziel"
            )

            Text("Ø \(Int(weekStats.averageKcal)) kcal/Tag · \(Int(abs(delta))) kcal \(deltaDirection) Ziel")
                .font(TypographyToken.caption)
                .foregroundStyle(ColorToken.secondaryText)
        }
        .cardBackground()
    }
}
