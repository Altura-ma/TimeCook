import Foundation

struct Dish: Identifiable, Codable {
    var id = UUID()
    var name: String
    var cookingTime: Int
    var level: String?
    var cookingMode: String?
    var cookingModeType: CookingModeType?
    var foodItemId: UUID?
    var lastTemperature: Int?
    var lastWeight: Int?

    var formattedTime: String {
        let m = cookingTime / 60
        let s = cookingTime % 60
        return s > 0 ? "\(m) min \(s) sec" : "\(m) min"
    }
}
