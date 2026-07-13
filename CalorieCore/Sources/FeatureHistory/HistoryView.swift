import Charts
import DesignSystem
import Domain
import SwiftUI

/// Verlauf-Tab: Wochen-/Monatsübersicht der kcal (Balkendiagramm + Zielinie), Tap auf einen Tag
/// führt zum Tages-Detail. Der bisherige „Diese Woche"-Chart vom Dashboard lebt hier weiter,
/// damit das Dashboard fokussiert bleibt.
public struct HistoryView: View {
    @State private var viewModel: HistoryViewModel
    @State private var selectedPeriod: Period = .month
    private let diaryRepository: any DiaryRepository
    private let goalsRepository: any GoalsRepository

    public enum Period: String, CaseIterable, Identifiable {
        case week = "Woche"
        case month = "Monat"

        public var id: String {
            rawValue
        }

        var days: Int {
            switch self {
            case .week: 7
            case .month: 30
            }
        }
    }

    public init(diaryRepository: any DiaryRepository, goalsRepository: any GoalsRepository) {
        self.diaryRepository = diaryRepository
        self.goalsRepository = goalsRepository
        _viewModel = State(initialValue: HistoryViewModel(diaryRepository: diaryRepository, goalsRepository: goalsRepository))
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Verlauf")
                .navigationDestination(for: String.self) { dayKey in
                    DayDetailView(dayKey: dayKey, diaryRepository: diaryRepository, goalsRepository: goalsRepository)
                }
                .task { await viewModel.load(days: selectedPeriod.days) }
                .onChange(of: selectedPeriod) { _, newValue in
                    Task { await viewModel.load(days: newValue.days) }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .empty:
            ContentUnavailableView("Keine Einträge in diesem Zeitraum", systemImage: "chart.bar")
        case let .error(message):
            ContentUnavailableView {
                Label("Fehler", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Erneut versuchen") { Task { await viewModel.load(days: selectedPeriod.days) } }
            }
        case let .loaded(stats):
            historyList(stats)
        }
    }

    private func historyList(_ stats: WeekStats) -> some View {
        List {
            Section {
                Picker("Zeitraum", selection: $selectedPeriod) {
                    ForEach(Period.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                chart(stats)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            Section("Tage") {
                ForEach(stats.days.reversed(), id: \.dayKey) { day in
                    NavigationLink(value: day.dayKey) {
                        dayRow(day)
                    }
                    .accessibilityIdentifier("history.dayRow.\(day.dayKey)")
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func chart(_ stats: WeekStats) -> some View {
        let goal = stats.days.last?.goals.dailyKcal ?? 0
        let delta = stats.deltaFromGoal
        let deltaDirection = delta <= 0 ? "unter" : "über"

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Chart {
                ForEach(stats.days, id: \.dayKey) { day in
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
            .frame(height: 140)
            .accessibilityLabel("Kalorienverlauf")
            .accessibilityValue(
                "Durchschnitt \(Int(stats.averageKcal)) Kilokalorien pro Tag, \(Int(abs(delta))) \(deltaDirection) Ziel"
            )

            Text("Ø \(Int(stats.averageKcal)) kcal/Tag · \(Int(abs(delta))) kcal \(deltaDirection) Ziel")
                .font(TypographyToken.caption)
                .foregroundStyle(ColorToken.secondaryText)
        }
        .cardBackground()
    }

    private func dayRow(_ day: DayTotals) -> some View {
        HStack {
            Text(formattedDay(day.dayKey))
                .font(TypographyToken.body)
            Spacer()
            Text("\(Int(day.kcal)) kcal")
                .font(TypographyToken.body)
                .foregroundStyle(
                    day.goals.dailyKcal > 0 && day.kcal > Double(day.goals.dailyKcal)
                        ? ColorToken.warning
                        : ColorToken.secondaryText
                )
        }
        .accessibilityElement(children: .combine)
    }

    private func formattedDay(_ dayKey: String) -> String {
        let parts = dayKey.split(separator: "-")
        guard parts.count == 3 else { return dayKey }
        return "\(parts[2]).\(parts[1]).\(parts[0])"
    }
}
