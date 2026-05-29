import Foundation

public struct CookingActivitySnapshot: Codable, Hashable, Sendable {
    public let title: String
    public let startedAt: Date
    public let endsAt: Date
    public let nextDishName: String?
    public let nextDishStartAt: Date?
    public let totalDishes: Int

    public init(title: String, startedAt: Date, endsAt: Date, nextDishName: String?, nextDishStartAt: Date?, totalDishes: Int) {
        self.title = title
        self.startedAt = startedAt
        self.endsAt = endsAt
        self.nextDishName = nextDishName
        self.nextDishStartAt = nextDishStartAt
        self.totalDishes = totalDishes
    }

    public static func make(plan: CookingPlan, startDate: Date) -> CookingActivitySnapshot? {
        guard plan.totalDuration > 0 else { return nil }
        let next = plan.steps.first { $0.startOffset > 0 }
        return CookingActivitySnapshot(
            title: plan.dishes.count > 1 ? "Multi-cuisson" : (plan.dishes.first?.name ?? "Cuisson"),
            startedAt: startDate,
            endsAt: startDate.addingTimeInterval(plan.totalDuration),
            nextDishName: next?.dish.name,
            nextDishStartAt: next.map { startDate.addingTimeInterval($0.startOffset) },
            totalDishes: plan.dishes.count
        )
    }
}
