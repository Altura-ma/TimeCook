import SwiftUI

struct AddDishView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (Dish) -> Void

    // Selection state
    @State private var dishName = ""
    @State private var selectedFood: FoodItem? = nil
    @State private var selectedMode: CookingModeType? = nil
    @State private var selectedLevel: CookingLevel? = nil
    @State private var temperature: Int = 180
    @State private var weight: Int = 200

    // Manual override
    @State private var useManual = false
    @State private var manualMinutes = ""

    let db = FoodDatabase.shared

    private var currentConfig: ModeConfig? {
        guard let food = selectedFood, let mode = selectedMode else { return nil }
        return food.config(for: mode)
    }

    private var computedTime: Int? {
        if useManual {
            guard let m = Int(manualMinutes), m > 0 else { return nil }
            return m * 60
        }
        guard let config = currentConfig else { return nil }
        return config.computeTime(
            level: selectedLevel,
            temp: config.defaultTemp != nil ? temperature : nil,
            weight: config.supportsWeight ? weight : nil
        )
    }

    private var canAdd: Bool {
        let nameOK = !dishName.trimmingCharacters(in: .whitespaces).isEmpty
        let timeOK = computedTime != nil
        let levelOK = useManual ||
            currentConfig?.levels == nil ||
            selectedLevel != nil
        return nameOK && timeOK && levelOK
    }

    var body: some View {
        NavigationView {
            Form {

                // ── Name ──────────────────────────────────────
                Section("Nom du plat") {
                    TextField("Ex : Steak, Légumes...", text: $dishName)
                }

                // ── Mode: Database vs Manual ──────────────────
                Section {
                    Toggle("Temps manuel", isOn: $useManual.animation())
                }

                if useManual {
                    Section("Durée") {
                        HStack {
                            TextField("Minutes", text: $manualMinutes)
                                .keyboardType(.numberPad)
                            Text("min").foregroundColor(.secondary)
                        }
                    }
                } else {
                    // ── Food picker ────────────────────────────
                    Section("Aliment") {
                        Picker("Choisir...", selection: $selectedFood) {
                            Text("— Choisir —").tag(nil as FoodItem?)
                            ForEach(FoodCategory.allCases) { cat in
                                let foods = db.items(for: cat)
                                if !foods.isEmpty {
                                    Section(cat.rawValue) {
                                        ForEach(foods) { food in
                                            Text(food.name).tag(food as FoodItem?)
                                        }
                                    }
                                }
                            }
                        }
                        .onChange(of: selectedFood) { _ in
                            selectedMode = nil
                            selectedLevel = nil
                        }
                    }

                    // ── Mode picker ────────────────────────────
                    if let food = selectedFood {
                        Section("Mode de cuisson") {
                            Picker("Mode", selection: $selectedMode) {
                                Text("— Choisir —").tag(nil as CookingModeType?)
                                ForEach(food.availableModes) { mode in
                                    Label(mode.rawValue, systemImage: mode.icon)
                                        .tag(mode as CookingModeType?)
                                }
                            }
                            .onChange(of: selectedMode) { newMode in
                                selectedLevel = nil
                                if let m = newMode, let config = food.config(for: m) {
                                    temperature = config.defaultTemp ?? 180
                                    weight = config.defaultWeight ?? 200
                                }
                            }
                        }
                    }

                    // ── Level picker ───────────────────────────
                    if let config = currentConfig, let levels = config.levels {
                        Section("Niveau de cuisson") {
                            Picker("Niveau", selection: $selectedLevel) {
                                Text("— Choisir —").tag(nil as CookingLevel?)
                                ForEach(levels) { level in
                                    Text(level.name).tag(level as CookingLevel?)
                                }
                            }
                        }
                    }

                    // ── Temperature ────────────────────────────
                    if let config = currentConfig,
                       config.defaultTemp != nil,
                       let minT = config.minTemp,
                       let maxT = config.maxTemp {
                        Section {
                            HStack {
                                Label("Température", systemImage: "thermometer.medium")
                                Spacer()
                                Text("\(temperature) °C")
                                    .foregroundColor(.orange).fontWeight(.semibold)
                                Stepper("", value: $temperature, in: minT...maxT, step: 10)
                                    .labelsHidden()
                            }
                            Text("Plage : \(minT)–\(maxT) °C — ajuste le temps automatiquement")
                                .font(.caption).foregroundColor(.secondary)
                        } header: {
                            Text("Température")
                        }
                    }

                    // ── Weight ─────────────────────────────────
                    if let config = currentConfig,
                       config.supportsWeight,
                       let minW = config.minWeight,
                       let maxW = config.maxWeight {
                        Section {
                            HStack {
                                Label("Poids (portion)", systemImage: "scalemass.fill")
                                Spacer()
                                Text("\(weight) g")
                                    .foregroundColor(.orange).fontWeight(.semibold)
                                Stepper("", value: $weight,
                                        in: minW...maxW, step: config.weightStep)
                                    .labelsHidden()
                            }
                            Text("Plage : \(minW)–\(maxW) g — ajuste le temps automatiquement")
                                .font(.caption).foregroundColor(.secondary)
                        } header: {
                            Text("Poids")
                        }
                    }

                    // ── Time preview ───────────────────────────
                    if let seconds = computedTime {
                        Section {
                            HStack {
                                Image(systemName: "clock.fill").foregroundColor(.orange)
                                Text("Durée estimée")
                                Spacer()
                                Text(formatTime(seconds))
                                    .fontWeight(.bold).foregroundColor(.orange)
                            }
                            if let config = currentConfig {
                                let summary = config.parameterSummary(temp: temperature, weight: weight)
                                if !summary.isEmpty {
                                    Text(summary).font(.caption).foregroundColor(.secondary)
                                }
                            }
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
                    Button("Ajouter", action: addDish).disabled(!canAdd)
                }
            }
        }
    }

    private func addDish() {
        guard let time = computedTime else { return }

        var modeLabel: String?
        if !useManual, let mode = selectedMode {
            var parts = [mode.rawValue]
            if let config = currentConfig {
                let summary = config.parameterSummary(temp: temperature, weight: weight)
                if !summary.isEmpty { parts.append(summary) }
            }
            modeLabel = parts.joined(separator: " · ")
        }

        let dish = Dish(
            name: dishName.trimmingCharacters(in: .whitespaces),
            cookingTime: time,
            level: selectedLevel?.name,
            cookingMode: modeLabel
        )
        onAdd(dish)
        dismiss()
    }
}

private func formatTime(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return s > 0 ? "\(m) min \(s) sec" : "\(m) min"
}
