import Foundation
import ActivityKit

@available(iOS 16.2, *)
@MainActor
final class LiveActivityService {
    static let shared = LiveActivityService()
    private init() {}

    private var activity: Activity<TimeCookAttributes>?
    private var stateTask: Task<Void, Never>?

    // MARK: - Public lifecycle

    func start(schedule: CookingSchedule, dishes: [Dish]) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        await endAllActivities()

        let attrs = TimeCookAttributes(
            sessionTitle: dishes.prefix(3).map(\.name).joined(separator: " · "),
            totalDishes: dishes.count
        )
        let content = ActivityContent(
            state: makeState(from: schedule),
            staleDate: schedule.targetEndTime.addingTimeInterval(120),
            relevanceScore: 1.0
        )

        do {
            activity = try Activity.request(attributes: attrs, content: content, pushType: nil)
            monitorState()
        } catch {
            print("[LiveActivity] start failed: \(error.localizedDescription)")
        }
    }

    func update(schedule: CookingSchedule, alertForDish dishName: String? = nil) async {
        guard let activity else { return }

        let content = ActivityContent(
            state: makeState(from: schedule),
            staleDate: schedule.targetEndTime.addingTimeInterval(120),
            relevanceScore: 1.0
        )
        let alert: AlertConfiguration? = dishName.map {
            AlertConfiguration(
                title: "TimeCook — C'est le moment !",
                body: "Lancez \($0) maintenant.",
                sound: .default
            )
        }
        await activity.update(content, alertConfiguration: alert)
    }

    func stop() async {
        stateTask?.cancel()
        stateTask = nil
        guard let current = activity else { return }
        let finalContent = ActivityContent(
            state: current.content.state,
            staleDate: nil,
            relevanceScore: 0
        )
        await current.end(finalContent, dismissalPolicy: .after(Date().addingTimeInterval(60)))
        activity = nil
    }

    /// Call on app launch to re-attach to any activity that survived a crash or relaunch.
    func restoreIfNeeded() {
        guard activity == nil,
              let existing = Activity<TimeCookAttributes>.activities.first else { return }
        activity = existing
        monitorState()
    }

    // MARK: - Private

    private func makeState(from schedule: CookingSchedule) -> TimeCookAttributes.ContentState {
        let now = Date()
        let completed = schedule.entries.filter { $0.startTime <= now }.count
        let next = schedule.entries.first { $0.startTime > now }
        return TimeCookAttributes.ContentState(
            targetEndTime: schedule.targetEndTime,
            completedDishes: completed,
            nextDishName: next?.dish.name,
            nextDishStartTime: next?.startTime
        )
    }

    private func endAllActivities() async {
        for existing in Activity<TimeCookAttributes>.activities {
            await existing.end(dismissalPolicy: .immediate)
        }
    }

    /// Observes iOS-triggered state changes (battery death, user dismissal, stale).
    private func monitorState() {
        guard let activity else { return }
        stateTask?.cancel()
        stateTask = Task { [weak self] in
            for await state in activity.activityStateUpdates {
                guard let self else { break }
                if state == .dismissed || state == .ended {
                    self.activity = nil
                    self.stateTask = nil
                    break
                }
            }
        }
    }
}
