import Foundation

struct Dish: Identifiable, Codable {
    var id = UUID()
    var name: String
    var cookingTime: Int  // seconds, pre-computed including all adjustments
    var level: String?
    var cookingMode: String?  // display string, e.g. "Air Fryer · 180°C · 200 g"

    var formattedTime: String {
        let m = cookingTime / 60
        let s = cookingTime % 60
        return s > 0 ? "\(m) min \(s) sec" : "\(m) min"
    }
}
