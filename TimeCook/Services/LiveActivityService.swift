import Foundation
import ActivityKit

@available(iOS 16.1, *)
class LiveActivityService {
    static let shared = LiveActivityService()
    private var activity: Activity<TimeCookAttributes>?

    func start(schedule: CookingSchedule, dishes: [Dish]) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let now = Date()
        let nextEntry = schedule.entries.first { $0.startTime > now }
        let title = dishes.prefix(3).map { $0.name }.joined(separator: " · ")

        let state = TimeCookAttributes.ContentState(
            targetEndTime: schedule.targetEndTime,
            nextDishName: nextEntry?.dish.name,
            nextDishStartTime: nextEntry?.startTime,
            totalDishes: dishes.count,
            sessionTitle: title
        )
        let attrs = TimeCookAttributes(startedAt: now)

        do {
            activity = try Activity.request(
                attributes: attrs,
                contentState: state,
                pushType: nil
            )
        } catch {
            print("Live Activity start error: \(error)")
        }
    }

    func update(schedule: CookingSchedule) {
        guard let activity else { return }
        let now = Date()
        let nextEntry = schedule.entries.first { $0.startTime > now && $0.startTime > now }

        let state = TimeCookAttributes.ContentState(
            targetEndTime: schedule.targetEndTime,
            nextDishName: nextEntry?.dish.name,
            nextDishStartTime: nextEntry?.startTime,
            totalDishes: schedule.entries.count,
            sessionTitle: activity.attributes.startedAt.formatted()
        )
        Task {
            await activity.update(using: state)
        }
    }

    func stop() {
        Task {
            await activity?.end(dismissalPolicy: .immediate)
            activity = nil
        }
    }
}
