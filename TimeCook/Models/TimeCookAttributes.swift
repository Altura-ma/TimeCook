import Foundation
import ActivityKit

// Shared with TimeCookWidgets extension (duplicated there)
@available(iOS 16.1, *)
struct TimeCookAttributes: ActivityAttributes {
    public typealias TimeCookStatus = ContentState

    public struct ContentState: Codable, Hashable {
        var targetEndTime: Date         // when all dishes are done
        var nextDishName: String?       // next dish to start (nil = none)
        var nextDishStartTime: Date?    // when to start it
        var totalDishes: Int
        var sessionTitle: String        // e.g. "Steak · Brocoli · Riz"
    }

    var startedAt: Date
}
