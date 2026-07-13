import Data
import Domain
import WidgetKit

struct CalorieEntry: TimelineEntry {
    let date: Date
    let totals: DayTotals?
}

/// Liest den App-Group-Store read-only – niemals schreibend, das bleibt der App vorbehalten.
struct CalorieTimelineProvider: TimelineProvider {
    func placeholder(in _: Context) -> CalorieEntry {
        CalorieEntry(date: Date(), totals: nil)
    }

    func getSnapshot(in _: Context, completion: @escaping (CalorieEntry) -> Void) {
        Task {
            await completion(makeEntry())
        }
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        Task {
            let entry = await makeEntry()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    private func makeEntry() async -> CalorieEntry {
        guard let container = try? ModelContainerFactory.makeAppGroupContainer(appGroupID: AppGroup.id) else {
            return CalorieEntry(date: Date(), totals: nil)
        }
        let diaryRepository = SwiftDataDiaryRepository(modelContainer: container)
        let goalsRepository = SwiftDataGoalsRepository(modelContainer: container)
        let getDayTotals = GetDayTotalsUseCase(diaryRepository: diaryRepository, goalsRepository: goalsRepository)
        let totals = try? await getDayTotals(dayKey: DayKey.make(for: Date()))
        return CalorieEntry(date: Date(), totals: totals)
    }
}
