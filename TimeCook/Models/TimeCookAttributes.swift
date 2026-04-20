import Foundation
import ActivityKit

// NOTE: Duplicated verbatim in TimeCookWidgets/TimeCookAttributes.swift.
// Widget extensions cannot import the main module — keep both in sync.
struct TimeCookAttributes: ActivityAttributes {
    // Static — set once at start, never mutated during the session.
    let sessionTitle: String   // "Steak · Brocoli · Riz"
    let totalDishes: Int

    struct ContentState: Codable, Hashable {
        var targetEndTime: Date
        /// Dishes whose startTime has already passed (currently cooking or done).
        var completedDishes: Int
        var nextDishName: String?
        var nextDishStartTime: Date?
    }
}
