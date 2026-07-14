import Charts
import DesignSystem
import Domain
import SwiftUI

/// Gewichts-Tab: aktuelle Zahl + Delta zur letzten Messung, Verlaufskurve über einen
/// wählbaren Zeitraum, Eintragen per Sheet, Swipe-to-delete auf die Historie.
public struct WeightView: View {
    @State private var viewModel: WeightViewModel
    @State private var isShowingAddSheet = false
    @State private var selectedPeriod: Period = .month

    public enum Period: String, CaseIterable, Identifiable {
        case week = "Woche"
        case month = "Monat"
        case all = "Alle"

        public var id: String {
            rawValue
        }

        var days: Int? {
            switch self {
            case .week: 7
            case .month: 30
            case .all: nil
            }
        }
    }

    public init(weightRepository: any WeightRepository, widgetRefreshing: any WidgetRefreshing) {
        _viewModel = State(initialValue: WeightViewModel(weightRepository: weightRepository, widgetRefreshing: widgetRefreshing))
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Gewicht")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink("Verlauf", destination: WeightHistoryView(viewModel: viewModel))
                            .accessibilityIdentifier("weight.historyLink")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Gewicht eintragen")
                        .accessibilityIdentifier("weight.addButton")
                    }
                }
                .sheet(isPresented: $isShowingAddSheet) {
                    WeightEntrySheet(initialCreatine: lastCreatineFlag) { weightKg, date, withCreatine in
                        await viewModel.save(weightKg: weightKg, date: date, withCreatine: withCreatine)
                        isShowingAddSheet = false
                    }
                }
                .task { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .empty:
            ContentUnavailableView {
                Label("Noch keine Messungen", systemImage: "scalemass")
            } description: {
                Text("Trag dein erstes Gewicht ein, um den Verlauf zu sehen.")
            } actions: {
                Button("Gewicht eintragen") { isShowingAddSheet = true }
            }
        case let .error(message):
            ContentUnavailableView {
                Label("Fehler", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Erneut versuchen") { Task { await viewModel.load() } }
            }
        case let .loaded(entries):
            history(for: entries)
        }
    }

    private func history(for entries: [WeightEntry]) -> some View {
        List {
            Section {
                header
                Picker("Zeitraum", selection: $selectedPeriod) {
                    ForEach(Period.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                chart(for: filtered(entries))
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            Section("Verlauf") {
                ForEach(entries.reversed()) { entry in
                    row(for: entry)
                        .swipeActions {
                            Button("Löschen", role: .destructive) {
                                Task { await viewModel.delete(entryID: entry.id) }
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var header: some View {
        VStack(spacing: Spacing.xs) {
            Text(formattedWeight(viewModel.trend?.latest?.weightKg))
                .font(TypographyToken.remainingKcal)
                .accessibilityIdentifier("weight.current")
            if let delta = viewModel.trend?.deltaFromPreviousMeasurement {
                deltaLabel(delta)
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.sm)
    }

    private func deltaLabel(_ delta: Double) -> some View {
        let isDecrease = delta < 0
        let color: Color = delta == 0 ? ColorToken.secondaryText : (isDecrease ? ColorToken.positive : ColorToken.warning)
        let symbol = delta == 0 ? "minus" : (isDecrease ? "arrow.down.right" : "arrow.up.right")
        return Label(String(format: "%.1f kg zur letzten Messung", abs(delta)), systemImage: symbol)
            .font(TypographyToken.caption)
            .foregroundStyle(color)
    }

    private func filtered(_ entries: [WeightEntry]) -> [WeightEntry] {
        guard let days = selectedPeriod.days else { return entries }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entries.filter { $0.recordedAt >= cutoff }
    }

    private func chart(for entries: [WeightEntry]) -> some View {
        Chart {
            ForEach(entries) { entry in
                LineMark(x: .value("Datum", entry.recordedAt), y: .value("kg", entry.weightKg))
                    .foregroundStyle(ColorToken.accent)
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("Datum", entry.recordedAt), y: .value("kg", entry.weightKg))
                    .foregroundStyle(ColorToken.accent)
            }
            ForEach(weeklyAveragesInRange) { average in
                LineMark(x: .value("Woche", average.weekStart), y: .value("Wochenmittel", average.averageKg))
                    .foregroundStyle(ColorToken.secondaryText)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .interpolationMethod(.monotone)
            }
        }
        .frame(height: 180)
        .accessibilityLabel("Gewichtsverlauf mit Wochenmittel")
        .accessibilityValue(chartAccessibilitySummary(entries))
        .cardBackground()
    }

    /// Wochenmittel-Punkte im aktuell gewählten Zeitraum (gestrichelte Trendlinie im Chart).
    private var weeklyAveragesInRange: [WeeklyWeightAverage] {
        guard let days = selectedPeriod.days else { return viewModel.weeklyAverages }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return viewModel.weeklyAverages.filter { $0.weekStart >= cutoff }
    }

    private func chartAccessibilitySummary(_ entries: [WeightEntry]) -> String {
        guard let first = entries.first, let last = entries.last else { return "Keine Daten im Zeitraum" }
        return "\(formattedWeight(first.weightKg)) bis \(formattedWeight(last.weightKg)) über \(entries.count) Messungen"
    }

    private func row(for entry: WeightEntry) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(entry.recordedAt, format: .dateTime.day().month().year())
                .font(TypographyToken.body)
            if entry.withCreatine {
                Text("Kreatin")
                    .font(TypographyToken.caption)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 2)
                    .background(ColorToken.accent.opacity(0.15), in: Capsule())
                    .foregroundStyle(ColorToken.accent)
                    .accessibilityLabel("mit Kreatin")
            }
            Spacer()
            Text(formattedWeight(entry.weightKg))
                .font(TypographyToken.body)
        }
        .accessibilityElement(children: .combine)
    }

    /// Neue Messungen übernehmen standardmäßig den Kreatin-Status der letzten Messung.
    private var lastCreatineFlag: Bool {
        viewModel.trend?.latest?.withCreatine ?? false
    }

    private func formattedWeight(_ weightKg: Double?) -> String {
        guard let weightKg else { return "–" }
        return String(format: "%.1f kg", weightKg)
    }
}
