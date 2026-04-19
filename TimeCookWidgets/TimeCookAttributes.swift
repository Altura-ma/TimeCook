import Foundation
import ActivityKit

// Duplicate of TimeCook/Models/TimeCookAttributes.swift
// Keep both in sync if you add fields.
@available(iOS 16.1, *)
struct TimeCookAttributes: ActivityAttributes {
    public typealias TimeCookStatus = ContentState

    public struct ContentState: Codable, Hashable {
        var targetEndTime: Date
        var nextDishName: String?
        var nextDishStartTime: Date?
        var totalDishes: Int
        var sessionTitle: String
    }

    var startedAt: Date
}
