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
            var startTime: Date
            var endTime: Date
            /// Set by the app at push time — avoids hash collisions when only the clock advances.
            var isCooking: Bool
        }
    }
}
