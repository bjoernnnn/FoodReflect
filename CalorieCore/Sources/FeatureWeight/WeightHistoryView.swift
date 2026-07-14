import DesignSystem
import Domain
import SwiftUI

/// Vollständige Tabelle aller Gewichtsmessungen mit Bearbeiten/Löschen, erreichbar aus dem
/// Gewichts-Tab. Teilt sich das `WeightViewModel` mit `WeightView`, lädt aber die komplette
/// Historie statt der 90-Tage-Vorgabe.
struct WeightHistoryView: View {
    let viewModel: WeightViewModel
    @State private var editingEntry: WeightEntry?

    var body: some View {
        content
            .navigationTitle("Gewichtsverlauf")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadAll() }
            .sheet(item: $editingEntry) { entry in
                WeightEntrySheet(existingEntry: entry) { weightKg, date, withCreatine in
                    await viewModel.save(entryID: entry.id, weightKg: weightKg, date: date, withCreatine: withCreatine)
                    editingEntry = nil
                }
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
            }
        case let .error(message):
            ContentUnavailableView {
                Label("Fehler", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Erneut versuchen") { Task { await viewModel.loadAll() } }
            }
        case let .loaded(entries):
            List {
                ForEach(entries.reversed()) { entry in
                    row(for: entry)
                        .contentShape(Rectangle())
                        .onTapGesture { editingEntry = entry }
                        .swipeActions {
                            Button("Löschen", role: .destructive) {
                                Task { await viewModel.delete(entryID: entry.id) }
                            }
                        }
                }
            }
            .listStyle(.plain)
        }
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
            Text(String(format: "%.1f kg", entry.weightKg))
                .font(TypographyToken.body)
        }
        .accessibilityElement(children: .combine)
    }
}
