import Foundation
import SwiftUI
import TimeCookCore

@MainActor
final class CookingStore: ObservableObject {
    @Published var dishes: [Dish] = [
        Dish(name: "Poulet", duration: 45 * 60),
        Dish(name: "Riz", duration: 12 * 60),
        Dish(name: "Légumes", duration: 8 * 60)
    ]
    @Published var activePlanStartDate: Date?
    @Published var errorMessage: String?

    var plan: CookingPlan { CookingPlan(dishes: dishes) }

    var isCooking: Bool { activePlanStartDate != nil }

    func addDish(name: String, minutes: Double) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, minutes > 0 else { return }
        dishes.append(Dish(name: trimmed, duration: minutes * 60))
    }

    func deleteDish(at offsets: IndexSet) {
        dishes.remove(atOffsets: offsets)
    }

    func startCooking() async {
        let currentPlan = plan
        guard currentPlan.totalDuration > 0 else { return }
        let startDate = Date()
        do {
            try await NotificationScheduler.shared.schedule(plan: currentPlan, startDate: startDate)
            await CookingLiveActivityController.shared.start(plan: currentPlan, startDate: startDate)
            activePlanStartDate = startDate
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopCooking() async {
        NotificationScheduler.shared.cancelCookingNotifications()
        await CookingLiveActivityController.shared.end()
        activePlanStartDate = nil
    }
}
