import SwiftUI

struct AddDishView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (Dish) -> Void

    @State private var dishName = ""
    @State private var minutes = ""
    @State private var seconds = "0"
    @State private var selectedFood: FoodItem? = nil
    @State private var selectedLevel: CookingLevel? = nil
    @State private var useDatabase = true

    let foods = FoodDatabase.shared.items

    var cookingTimeSeconds: Int? {
        if useDatabase {
            if let level = selectedLevel { return level.time }
            if let food = selectedFood, let t = food.defaultTime { return t }
            return nil
        }
        let m = Int(minutes) ?? 0
        let s = Int(seconds) ?? 0
        let total = m * 60 + s
        return total > 0 ? total : nil
    }

    var canAdd: Bool {
        !dishName.trimmingCharacters(in: .whitespaces).isEmpty && cookingTimeSeconds != nil
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Nom du plat") {
                    TextField("Ex : Steak, Légumes...", text: $dishName)
                }

                Section("Temps de cuisson") {
                    Toggle("Depuis la base de données", isOn: $useDatabase.animation())

                    if useDatabase {
                        Picker("Aliment", selection: $selectedFood) {
                            Text("Choisir...").tag(nil as FoodItem?)
                            ForEach(foods) { food in
                                Text(food.name).tag(food as FoodItem?)
                            }
                        }
                        .onChange(of: selectedFood) { _ in selectedLevel = nil }

                        if let food = selectedFood, let levels = food.levels {
                            Picker("Cuisson", selection: $selectedLevel) {
                                Text("Choisir...").tag(nil as CookingLevel?)
                                ForEach(levels) { level in
                                    Text("\(level.name) (\(level.time / 60) min)")
                                        .tag(level as CookingLevel?)
                                }
                            }
                        }

                        if let t = cookingTimeSeconds {
                            Label(
                                t % 60 > 0 ? "Durée : \(t/60) min \(t%60) sec" : "Durée : \(t/60) min",
                                systemImage: "clock"
                            )
                            .foregroundColor(.orange)
                        }
                    } else {
                        HStack {
                            TextField("Min", text: $minutes)
                                .keyboardType(.numberPad)
                                .frame(width: 70)
                            Text("min")
                            TextField("Sec", text: $seconds)
                                .keyboardType(.numberPad)
                                .frame(width: 70)
                            Text("sec")
                        }
                    }
                }
            }
            .navigationTitle("Nouveau plat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter", action: addDish)
                        .disabled(!canAdd)
                }
            }
        }
    }

    private func addDish() {
        guard let time = cookingTimeSeconds else { return }
        let dish = Dish(
            name: dishName.trimmingCharacters(in: .whitespaces),
            cookingTime: time,
            level: selectedLevel?.name
        )
        onAdd(dish)
        dismiss()
    }
}
