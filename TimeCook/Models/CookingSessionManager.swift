import Foundation
import Combine

class CookingSessionManager: ObservableObject {

    @Published var pendingDishes: [Dish] = []
    @Published var schedule = CookingSchedule()
    @Published var isSessionActive = false

    private var liveActivityTasks: [Task<Void, Never>] = []

    // MARK: - Dish management

    func addDish(_ dish: Dish) { pendingDishes.append(dish) }

    func updateDish(_ dish: Dish) {
        guard let idx = pendingDishes.firstIndex(where: { $0.id == dish.id }) else { return }
        pendingDishes[idx] = dish
    }

    func removeDish(at offsets: IndexSet) { pendingDishes.remove(atOffsets: offsets) }
    func removeDish(id: UUID) { pendingDishes.removeAll { $0.id == id } }
    func clearDishes() { pendingDishes.removeAll() }

    // MARK: - Session lifecycle

    func startSession() {
        schedule.calculate(dishes: pendingDishes)
        NotificationService.shared.scheduleSession(entries: schedule.entries)

        if #available(iOS 16.2, *) {
            let snapshot = schedule
            let dishes = pendingDishes
            Task { @MainActor in
                await LiveActivityService.shared.start(schedule: snapshot, dishes: dishes)
            }
            scheduleLiveActivityUpdates()
        }
        isSessionActive = true
    }

    func stopSession() {
        cancelLiveActivityUpdates()
        NotificationService.shared.cancelAll()

        if #available(iOS 16.2, *) {
            Task { @MainActor in
                await LiveActivityService.shared.stop()
            }
        }
        isSessionActive = false
        schedule = CookingSchedule()
    }

    // MARK: - Live Activity update scheduling

    /// Schedules a Task per dish that fires at its startTime, updating the Live Activity
    /// and triggering an alert banner asking the user to put that dish on heat.
    @available(iOS 16.2, *)
    private func scheduleLiveActivityUpdates() {
        cancelLiveActivityUpdates()

        for entry in schedule.entries {
            let delay = entry.startTime.timeIntervalSinceNow
            guard delay > 0.5 else { continue }

            let dishName = entry.dish.name
            let snapshot = schedule

            let task = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { return }
                await LiveActivityService.shared.update(
                    schedule: snapshot,
                    alertForDish: dishName
                )
            }
            liveActivityTasks.append(task)
        }
    }

    private func cancelLiveActivityUpdates() {
        liveActivityTasks.forEach { $0.cancel() }
        liveActivityTasks.removeAll()
    }
}
