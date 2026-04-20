import Foundation
import ActivityKit

// NOTE: Duplicated verbatim in TimeCookWidgets/TimeCookAttributes.swift — keep both in sync.
struct TimeCookAttributes: ActivityAttributes {
    let sessionTitle: String
    let totalDishes: Int

    struct ContentState: Codable, Hashable {
        var targetEndTime: Date
        /// All dishes ordered by startTime ascending (longest cook time first).
        var dishes: [DishStatus]

        struct DishStatus: Codable, Hashable, Identifiable {
            var id: UUID
            var name: String
            /// Absolute time when this dish should start cooking.
            var startTime: Date
            /// Absolute time when this dish finishes (== targetEndTime for all dishes).
            var endTime: Date
        }
    }
}
