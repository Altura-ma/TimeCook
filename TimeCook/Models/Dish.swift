import Foundation

struct Dish: Identifiable, Codable {
    var id = UUID()
    var name: String
    var cookingTime: Int  // seconds
    var level: String?

    var formattedTime: String {
        let m = cookingTime / 60
        let s = cookingTime % 60
        return s > 0 ? "\(m) min \(s) sec" : "\(m) min"
    }
}
