import Domain
import Foundation
import Sync

/// iPhone-Seite der Watch-Synchronisation (Composition-Root-nah): verbindet `PhoneSyncService`
/// mit den App-Repositories/UseCases. Empfangene Watch-Events werden auf die SwiftData-Stores
/// angewandt, danach wird ein frischer autoritativer Snapshot zur Watch gepusht.
///
/// **Hardware-Hinweis:** Die tatsächliche WCSession-Zustellung ist nur mit gekoppelter Apple
/// Watch verifizierbar. Anwenden/Rückgängig, Idempotenz und Snapshot-Aufbau sind entkoppelt
/// getestet (`SyncTests`); dieser Koordinator ist die dünne App-Verdrahtung darüber.
@MainActor
final class WatchSyncCoordinator {
    private let diaryRepository: any DiaryRepository
    private let weightRepository: any WeightRepository
    private let mealTemplateRepository: any MealTemplateRepository
    private let quickListRepository: any QuickListRepository
    private let goalsRepository: any GoalsRepository
    private let calendar: Calendar

    private let logQuickEntry: LogQuickEntryUseCase
    private let getDayTotals: GetDayTotalsUseCase
    private let getLatestWeight: GetLatestWeightUseCase

    private var phoneSync: PhoneSyncService?
    /// Merkt sich, welche Einträge ein Watch-Event erzeugt hat – für `revert` (Undo).
    private var createdByEvent: [UUID: [Deletion]] = [:]

    private enum Deletion {
        case diary(UUID)
        case weight(UUID)
    }

    init(
        diaryRepository: any DiaryRepository,
        weightRepository: any WeightRepository,
        mealTemplateRepository: any MealTemplateRepository,
        quickListRepository: any QuickListRepository,
        goalsRepository: any GoalsRepository,
        calendar: Calendar = .current
    ) {
        self.diaryRepository = diaryRepository
        self.weightRepository = weightRepository
        self.mealTemplateRepository = mealTemplateRepository
        self.quickListRepository = quickListRepository
        self.goalsRepository = goalsRepository
        self.calendar = calendar
        logQuickEntry = LogQuickEntryUseCase(mealTemplateRepository: mealTemplateRepository)
        getDayTotals = GetDayTotalsUseCase(diaryRepository: diaryRepository, goalsRepository: goalsRepository)
        getLatestWeight = GetLatestWeightUseCase(weightRepository: weightRepository)
    }

    /// Aktiviert die WCSession und pusht den ersten Snapshot. Beim App-Start aufrufen.
    func start() async {
        let service = PhoneSyncService(
            processedEventStore: InMemoryProcessedEventStore(),
            onEvent: { [weak self] event in await self?.handle(event) }
        )
        service.activate()
        phoneSync = service
        await pushSnapshot()
    }

    /// Baut den autoritativen Snapshot aus den aktuellen Daten und schickt ihn zur Watch.
    /// Bei jeder relevanten iPhone-Änderung + nach jedem Watch-Event aufrufen.
    func pushSnapshot() async {
        guard let phoneSync else { return }
        guard let snapshot = await currentSnapshot() else { return }
        phoneSync.push(snapshot)
    }

    // MARK: - Event-Anwendung

    private func handle(_ event: WatchEvent) async {
        await apply(event)
        await pushSnapshot()
    }

    private func apply(_ event: WatchEvent) async {
        switch event.kind {
        case let .logWeight(weightKg, creatine):
            let entry = WeightEntry(
                dayKey: DayKey.make(for: event.occurredAt, calendar: calendar),
                weightKg: weightKg,
                recordedAt: event.occurredAt,
                withCreatine: creatine
            )
            try? await weightRepository.save(entry)
            createdByEvent[event.id] = [.weight(entry.id)]

        case let .logQuick(reference):
            let leaf = WatchSnapshotMapper.leaf(from: reference)
            guard let entries = try? await logQuickEntry(leaf: leaf, consumedAt: event.occurredAt, calendar: calendar) else {
                return
            }
            for entry in entries {
                try? await diaryRepository.save(entry)
            }
            createdByEvent[event.id] = entries.map { .diary($0.id) }

        case let .revert(eventID):
            guard let deletions = createdByEvent[eventID] else { return }
            for deletion in deletions {
                switch deletion {
                case let .diary(id): try? await diaryRepository.delete(entryID: id)
                case let .weight(id): try? await weightRepository.delete(entryID: id)
                }
            }
            createdByEvent[eventID] = nil
        }
    }

    // MARK: - Snapshot-Aufbau

    private func currentSnapshot() async -> WatchSnapshot? {
        let dayKey = DayKey.make(for: Date(), calendar: calendar)
        guard let totals = try? await getDayTotals(dayKey: dayKey) else { return nil }
        let latestWeight = try? await getLatestWeight()
        let quickList = await (try? quickListRepository.load()) ?? .empty
        let templates = await (try? mealTemplateRepository.all()) ?? []
        return WatchSnapshotMapper.snapshot(
            dayTotals: totals,
            latestWeight: latestWeight ?? nil,
            quickList: quickList,
            templates: templates
        )
    }
}
