import SwiftUI
import Sync

/// Schnellauswahl in exakt der iPhone-Reihenfolge. Kurzer Tap zeigt Details, Long-Press (0,6 s)
/// loggt (Fortschrittsring + Haptik). Nach dem Loggen 5 s ein Undo-Toast.
struct WatchQuickSelectView: View {
    let sync: WatchSyncService

    @State private var detailItem: WatchQuickItem?
    @State private var lastLog: LoggedEntry?

    private struct LoggedEntry: Equatable {
        let event: WatchEvent
        let item: WatchQuickItem
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content
            if let lastLog {
                undoToast(for: lastLog)
            }
        }
        .navigationTitle("Schnellauswahl")
        .sheet(item: $detailItem) { item in
            WatchQuickDetailView(item: item)
        }
    }

    @ViewBuilder
    private var content: some View {
        if sync.snapshot.quickItems.isEmpty {
            ContentUnavailableView {
                Label("Leer", systemImage: "bolt.slash")
            } description: {
                Text("Schnellauswahl auf dem iPhone einrichten.")
            }
        } else {
            List(sync.snapshot.quickItems) { item in
                WatchQuickRow(item: item) { detailItem = item } onLog: { log(item) }
            }
        }
    }

    private func undoToast(for logged: LoggedEntry) -> some View {
        HStack {
            Text("Geloggt")
                .font(.footnote)
            Spacer()
            Button("Rückgängig") { undo(logged) }
                .font(.footnote)
                .tint(WatchTheme.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .task(id: logged.event.id) {
            // Toast nach 5 s automatisch ausblenden.
            try? await Task.sleep(for: .seconds(5))
            if lastLog?.event.id == logged.event.id {
                withAnimation { lastLog = nil }
            }
        }
    }

    private func log(_ item: WatchQuickItem) {
        let event = WatchEvent(id: UUID(), kind: .logQuick(reference: item.reference), occurredAt: Date())
        sync.send(event)
        sync.applyOptimistic { $0.consumedKcal += item.kcal }
        withAnimation { lastLog = LoggedEntry(event: event, item: item) }
    }

    private func undo(_ logged: LoggedEntry) {
        let revert = WatchEvent(id: UUID(), kind: .revert(eventID: logged.event.id), occurredAt: Date())
        sync.send(revert)
        sync.applyOptimistic { $0.consumedKcal -= logged.item.kcal }
        withAnimation { lastLog = nil }
    }
}

/// Eine Zeile mit Tap→Detail und Long-Press→Loggen; der Ring füllt sich während des Haltens.
private struct WatchQuickRow: View {
    let item: WatchQuickItem
    let onTap: () -> Void
    let onLog: () -> Void

    @State private var progress: Double = 0
    @State private var didLog = false

    var body: some View {
        HStack(spacing: 8) {
            if let folderName = item.folderName {
                Image(systemName: "folder")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Ordner \(folderName)")
            }
            Image(systemName: item.isMeal ? "fork.knife" : "leaf")
                .font(.caption)
                .foregroundStyle(WatchTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)
                    .lineLimit(1)
                Text("\(Int(item.kcal.rounded())) kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Circle()
                .trim(from: 0, to: progress)
                .stroke(WatchTheme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 20, height: 20)
                .opacity(progress > 0 ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onLongPressGesture(minimumDuration: 0.6, maximumDistance: 40) {
            didLog.toggle()
            onLog()
        } onPressingChanged: { pressing in
            withAnimation(pressing ? .linear(duration: 0.6) : .easeOut(duration: 0.15)) {
                progress = pressing ? 1 : 0
            }
        }
        .sensoryFeedback(.success, trigger: didLog)
    }
}

/// Detail-Sheet (kurzer Tap): zeigt kcal und ob es ein Gericht ist. Loggt nichts.
private struct WatchQuickDetailView: View {
    let item: WatchQuickItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 8) {
            Text(item.title)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("\(Int(item.kcal.rounded())) kcal")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(WatchTheme.accent)
            Text(item.isMeal ? "Gericht" : "Lebensmittel")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Schließen") { dismiss() }
                .padding(.top, 4)
        }
        .padding()
    }
}
