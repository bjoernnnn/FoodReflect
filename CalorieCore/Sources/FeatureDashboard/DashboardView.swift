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
    private let diaryRepository: any DiaryRepository
    private let widgetRefreshing: any WidgetRefreshing

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
        self.diaryRepository = diaryRepository
        self.widgetRefreshing = widgetRefreshing
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
                .navigationDestination(for: DiaryEntry.self) { entry in
                    EntryDetailView(
                        entry: entry,
                        diaryRepository: diaryRepository,
                        widgetRefreshing: widgetRefreshing,
                        onChange: { Task { await viewModel.load() } }
                    )
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
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            Section("Heutige Einträge") {
                if viewModel.todayEntries.isEmpty {
                    Label("Noch nichts erfasst – tippe unten auf Erfassen, um zu starten.", systemImage: "tray")
                        .font(TypographyToken.body)
                        .foregroundStyle(ColorToken.secondaryText)
                } else {
                    ForEach(viewModel.todayEntries) { entry in
                        NavigationLink(value: entry) {
                            entryRow(entry)
                        }
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
        .sensoryFeedback(.success, trigger: viewModel.todayEntries.count)
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
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(ColorToken.accent.opacity(0.12))
                    .frame(width: 260, height: 260)
                    .blur(radius: 30)
                SegmentedProgressRing(segments: macroRingSegments(totals), total: Double(totals.goals.dailyKcal))
                    .frame(width: 230, height: 230)
                    .accessibilityHidden(true)
                VStack {
                    Text("\(Int(totals.remainingKcal))")
                        .font(.system(size: remainingKcalFontSize, weight: .bold, design: .rounded))
                    Text("kcal übrig")
                        .font(TypographyToken.caption)
                        .foregroundStyle(ColorToken.secondaryText)
                }
                .multilineTextAlignment(.center)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("dashboard.remainingKcal")
            }
            macroLegend
            Text("\(Int(totals.kcal)) konsumiert / \(totals.goals.dailyKcal) Ziel")
                .font(TypographyToken.body)
                .foregroundStyle(ColorToken.secondaryText)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("dashboard.consumedSummary")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.lg)
    }

    private func macroRingSegments(_ totals: DayTotals) -> [RingSegment] {
        [
            RingSegment(value: max(totals.protein * 4, 0), color: ColorToken.proteinColor),
            RingSegment(value: max(totals.carbs * 4, 0), color: ColorToken.carbsColor),
            RingSegment(value: max(totals.fat * 9, 0), color: ColorToken.fatColor)
        ]
    }

    private var macroLegend: some View {
        HStack(spacing: Spacing.md) {
            legendDot(color: ColorToken.proteinColor, label: "P")
            legendDot(color: ColorToken.carbsColor, label: "K")
            legendDot(color: ColorToken.fatColor, label: "F")
        }
        .accessibilityHidden(true)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(TypographyToken.caption).foregroundStyle(ColorToken.secondaryText)
        }
    }

    private func macrosSection(_ totals: DayTotals) -> some View {
        VStack(spacing: Spacing.md) {
            Chart {
                SectorMark(angle: .value("Protein", max(totals.protein * 4, 0)), innerRadius: .ratio(0.6))
                    .foregroundStyle(ColorToken.proteinColor)
                SectorMark(angle: .value("Kohlenhydrate", max(totals.carbs * 4, 0)), innerRadius: .ratio(0.6))
                    .foregroundStyle(ColorToken.carbsColor)
                SectorMark(angle: .value("Fett", max(totals.fat * 9, 0)), innerRadius: .ratio(0.6))
                    .foregroundStyle(ColorToken.fatColor)
            }
            .frame(height: 120)
            .accessibilityLabel("Makro-Verteilung")
            .accessibilityValue(
                "\(Int(totals.protein))g Protein, \(Int(totals.carbs))g Kohlenhydrate, \(Int(totals.fat))g Fett"
            )

            MacroBar(
                title: "Protein", currentGrams: totals.protein, targetGrams: Double(totals.goals.proteinGrams),
                tint: ColorToken.proteinColor
            )
            MacroBar(
                title: "Kohlenhydrate",
                currentGrams: totals.carbs,
                targetGrams: Double(totals.goals.carbsGrams),
                tint: ColorToken.carbsColor
            )
            MacroBar(
                title: "Fett", currentGrams: totals.fat, targetGrams: Double(totals.goals.fatGrams),
                tint: ColorToken.fatColor
            )
        }
        .cardBackground()
    }
}
