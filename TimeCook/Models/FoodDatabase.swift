import Foundation

struct CookingLevel: Identifiable, Hashable {
    let id: UUID
    let name: String
    let time: Int  // seconds

    init(name: String, time: Int) {
        self.id = UUID()
        self.name = name
        self.time = time
    }
}

struct FoodItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let levels: [CookingLevel]?
    let defaultTime: Int?  // seconds, used when no levels

    init(name: String, levels: [CookingLevel]? = nil, defaultTime: Int? = nil) {
        self.id = UUID()
        self.name = name
        self.levels = levels
        self.defaultTime = defaultTime
    }

    static func == (lhs: FoodItem, rhs: FoodItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

class FoodDatabase {
    static let shared = FoodDatabase()

    let items: [FoodItem] = [
        FoodItem(name: "Steak", levels: [
            CookingLevel(name: "Saignant", time: 360),
            CookingLevel(name: "À point", time: 480),
            CookingLevel(name: "Bien cuit", time: 600)
        ]),
        FoodItem(name: "Œuf", levels: [
            CookingLevel(name: "Mollet", time: 360),
            CookingLevel(name: "Dur", time: 540)
        ]),
        FoodItem(name: "Saumon", levels: [
            CookingLevel(name: "Rosé", time: 360),
            CookingLevel(name: "Bien cuit", time: 540)
        ]),
        FoodItem(name: "Pâtes", levels: [
            CookingLevel(name: "Al dente", time: 480),
            CookingLevel(name: "Bien cuites", time: 600)
        ]),
        FoodItem(name: "Poulet (filet)", defaultTime: 900),
        FoodItem(name: "Poisson (filet)", defaultTime: 420),
        FoodItem(name: "Brocoli vapeur", defaultTime: 300),
        FoodItem(name: "Riz blanc", defaultTime: 720),
        FoodItem(name: "Carottes", defaultTime: 480),
        FoodItem(name: "Pommes de terre", defaultTime: 1200),
        FoodItem(name: "Haricots verts", defaultTime: 420),
        FoodItem(name: "Épinards", defaultTime: 180),
        FoodItem(name: "Courgettes", defaultTime: 300),
        FoodItem(name: "Bacon", defaultTime: 300),
        FoodItem(name: "Saucisse", defaultTime: 600),
    ]
}
