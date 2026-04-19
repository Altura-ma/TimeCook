import Foundation
import Combine

// Shared app-level state — survives navigation changes.
class CookingSessionManager: ObservableObject {

    // ── Multi-cooking pending list ──────────────────────────────────
    @Published var pendingDishes: [Dish] = []

    // ── Active session ──────────────────────────────────────────────
    @Published var schedule = CookingSchedule()
    @Published var isSessionActive = false

    // ── Dish list management ────────────────────────────────────────

    func addDish(_ dish: Dish) {
        pendingDishes.append(dish)
    }

    func updateDish(_ dish: Dish) {
        guard let idx = pendingDishes.firstIndex(where: { $0.id == dish.id }) else { return }
        pendingDishes[idx] = dish
    }

    func removeDish(at offsets: IndexSet) {
        pendingDishes.remove(atOffsets: offsets)
    }

    func removeDish(id: UUID) {
        pendingDishes.removeAll { $0.id == id }
    }

    func clearDishes() {
        pendingDishes.removeAll()
    }

    // ── Session lifecycle ────────────────────────────────────────────

    func startSession() {
        schedule.calculate(dishes: pendingDishes)
        NotificationService.shared.scheduleSession(entries: schedule.entries)
        if #available(iOS 16.1, *) {
            LiveActivityService.shared.start(schedule: schedule, dishes: pendingDishes)
        }
        isSessionActive = true
    }

    func stopSession() {
        NotificationService.shared.cancelAll()
        if #available(iOS 16.1, *) {
            LiveActivityService.shared.stop()
        }
        isSessionActive = false
        schedule = CookingSchedule()
    }
}
