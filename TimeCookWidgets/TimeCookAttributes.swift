import Foundation
import ActivityKit

// NOTE: Duplicate of TimeCook/Models/TimeCookAttributes.swift — keep both in sync.
struct TimeCookAttributes: ActivityAttributes {
    let sessionTitle: String
    let totalDishes: Int

    struct ContentState: Codable, Hashable {
        var targetEndTime: Date
        var completedDishes: Int
        var nextDishName: String?
        var nextDishStartTime: Date?
    }
}
