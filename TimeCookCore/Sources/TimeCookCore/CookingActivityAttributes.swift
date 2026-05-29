import Foundation

#if os(iOS) && canImport(ActivityKit)
import ActivityKit

@available(iOS 16.2, *)
public struct CookingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var endsAt: Date
        public var nextDishName: String?
        public var nextDishStartAt: Date?

        public init(endsAt: Date, nextDishName: String?, nextDishStartAt: Date?) {
            self.endsAt = endsAt
            self.nextDishName = nextDishName
            self.nextDishStartAt = nextDishStartAt
        }
    }

    public var title: String
    public var totalDishes: Int

    public init(title: String, totalDishes: Int) {
        self.title = title
        self.totalDishes = totalDishes
    }
}
#endif
