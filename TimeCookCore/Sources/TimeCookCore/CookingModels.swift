import Foundation

public struct Dish: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var duration: TimeInterval

    public init(id: UUID = UUID(), name: String, duration: TimeInterval) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.duration = max(0, duration)
    }
}

public struct CookingStep: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID { dish.id }
    public let dish: Dish
    /// Seconds after the common cooking start at which this dish must be started.
    public let startOffset: TimeInterval
    public let endOffset: TimeInterval

    public init(dish: Dish, startOffset: TimeInterval, endOffset: TimeInterval) {
        self.dish = dish
        self.startOffset = startOffset
        self.endOffset = endOffset
    }
}

public struct CookingPlan: Codable, Equatable, Sendable {
    public let dishes: [Dish]
    public let steps: [CookingStep]
    public let totalDuration: TimeInterval

    public init(dishes: [Dish]) {
        let valid = dishes.filter { !$0.name.isEmpty && $0.duration > 0 }
        let total = valid.map(\.duration).max() ?? 0
        self.dishes = valid
        self.totalDuration = total
        self.steps = valid
            .map { dish in
                CookingStep(dish: dish, startOffset: total - dish.duration, endOffset: total)
            }
            .sorted { lhs, rhs in
                if lhs.startOffset == rhs.startOffset { return lhs.dish.duration > rhs.dish.duration }
                return lhs.startOffset < rhs.startOffset
            }
    }
}

public enum CookingPlanFormatter {
    public static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return String(format: "%ds", s)
    }
}
