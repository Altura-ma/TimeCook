import Foundation

struct ScheduleEntry: Identifiable {
    let id = UUID()
    let dish: Dish
    let startTime: Date
    let endTime: Date
    let notificationId: String
}

class CookingSchedule: ObservableObject {
    @Published var entries: [ScheduleEntry] = []
    @Published var targetEndTime: Date = Date()
    @Published var isRunning = false

    func calculate(dishes: [Dish]) {
        guard !dishes.isEmpty else { return }

        let maxTime = dishes.map { $0.cookingTime }.max() ?? 0
        let now = Date()
        let endTime = now.addingTimeInterval(TimeInterval(maxTime))

        entries = dishes.map { dish in
            ScheduleEntry(
                dish: dish,
                startTime: endTime.addingTimeInterval(TimeInterval(-dish.cookingTime)),
                endTime: endTime,
                notificationId: UUID().uuidString
            )
        }
        .sorted { $0.startTime < $1.startTime }

        targetEndTime = endTime
    }
}
