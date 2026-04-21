import SwiftUI

// MARK: - Context

enum DishConfigContext {
    case simpleTimer              // "Lancer le timer" button
    case addToList                // "Ajouter à la liste" button
    case editInList               // "Modifier" button
}

// MARK: - Main sheet

struct DishConfigSheet: View {
    @Environment(\.dismiss) private var dismiss

    let food: FoodItem
    let context: DishConfigContext
    var existingDish: Dish? = nil
    let onConfirm: (Dish) -> Void           // returns configured Dish
    var onLaunchTimer: ((Dish) -> Void)? = nil  // only used in simpleTimer mode

    // ── Internal state ──────────────────────────────────────────────
    @State private var dishName: String = ""
    @State private var selectedMode: CookingModeType? = nil
    @State private var selectedLevel: CookingLevel? = nil
    @State private var temperature: Int = 180
    @State private var weight: Int = 200

    private var currentConfig: ModeConfig? {
        guard let mode = selectedMode else { return nil }
        return food.config(for: mode)
    }

    private var computedTime: Int? {
        guard let config = currentConfig else { return nil }
        let hasLevel = config.levels != nil
        if hasLevel && selectedLevel == nil { return nil }
        return config.computeTime(
            level: selectedLevel,
            temp: config.defaultTemp != nil ? temperature : nil,
            weight: config.supportsWeight ? weight : nil
        )
    }

    private var canConfirm: Bool {
        !dishName.trimmingCharacters(in: .whitespaces).isEmpty && computedTime != nil
    }

    // ── Button labels ───────────────────────────────────────────────
    private var confirmLabel: String {
        switch context {
        case .simpleTimer:  return "Lancer le timer"
        case .addToList:    return "Ajouter à la liste"
        case .editInList:   return "Modifier"
        }
    }
    private var confirmIcon: String {
        switch context {
        case .simpleTimer:  return "play.circle.fill"
        case .addToList:    return "plus.circle.fill"
        case .editInList:   return "checkmark.circle.fill"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    dishNameSection
                    Divider().padding(.horizontal)
                    modeSection
                    levelSection
                    temperatureSection
                    weightSection
                    timePreviewSection
                    actionSection
                }
                .padding(.top)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear { prepopulate() }
    }

    private var headerSection: some View {
        HStack(spacing: 14) {
            Text(food.category.icon)
                .font(.system(size: 44))
                .frame(width: 72, height: 72)
                .background(Color(hex: food.category.colorHex).opacity(0.15))
                .cornerRadius(18)
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name).font(.title2).fontWeight(.bold)
                Text(food.category.rawValue).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private var dishNameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Nom du plat", systemImage: "pencil").font(.headline).padding(.horizontal)
            TextField("Ex : Mon steak, Légumes du soir…", text: $dishName)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Mode de cuisson", systemImage: "flame").font(.headline).padding(.horizontal)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90, maximum: 120))], spacing: 10) {
                ForEach(food.availableModes) { mode in
                    ModeButton(mode: mode, isSelected: selectedMode == mode) { pickMode(mode) }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var levelSection: some View {
        if let config = currentConfig, let levels = config.levels {
            Divider().padding(.horizontal)
            VStack(alignment: .leading, spacing: 10) {
                Label("Niveau de cuisson", systemImage: "thermometer.medium").font(.headline).padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(levels) { level in
                            ConfigChip(label: level.name, isSelected: selectedLevel?.id == level.id) { selectedLevel = level }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    private var temperatureSection: some View {
        if let config = currentConfig, config.defaultTemp != nil, let minT = config.minTemp, let maxT = config.maxTemp {
            Divider().padding(.horizontal)
            VStack(alignment: .leading, spacing: 10) {
                Label("Température", systemImage: "thermometer.sun.fill").font(.headline).padding(.horizontal)
                ConfigParamRow(value: "\(temperature) °C", hint: "\(minT)–\(maxT) °C • ajuste le temps") {
                    Stepper("", value: $temperature, in: minT...maxT, step: 10).labelsHidden()
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private var weightSection: some View {
        if let config = currentConfig, config.supportsWeight, let minW = config.minWeight, let maxW = config.maxWeight {
            Divider().padding(.horizontal)
            VStack(alignment: .leading, spacing: 10) {
                Label("Poids (portion)", systemImage: "scalemass").font(.headline).padding(.horizontal)
                ConfigParamRow(value: "\(weight) g", hint: "\(minW)–\(maxW) g • ajuste le temps") {
                    Stepper("", value: $weight, in: minW...maxW, step: currentConfig?.weightStep ?? 50).labelsHidden()
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private var timePreviewSection: some View {
        if let seconds = computedTime {
            Divider().padding(.horizontal)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Durée estimée").font(.subheadline).foregroundColor(.secondary)
                    if let config = currentConfig {
                        let s = config.parameterSummary(temp: temperature, weight: weight)
                        if !s.isEmpty {
                            Text(s).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                Text(formatDuration(seconds)).font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(.orange)
            }
            .padding(.horizontal)
        }
    }

    private var actionSection: some View {
        VStack(spacing: 10) {
            Button(action: confirm) {
                Label(confirmLabel, systemImage: confirmIcon)
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(canConfirm ? Color.orange : Color.gray)
                    .cornerRadius(14)
            }
            .disabled(!canConfirm)
            Button("Annuler") { dismiss() }.font(.subheadline).foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    // MARK: - Logic

    private func pickMode(_ mode: CookingModeType) {
        guard let config = food.config(for: mode) else { return }
        selectedMode = mode
        selectedLevel = nil
        temperature = config.defaultTemp ?? 180
        weight = config.defaultWeight ?? 200
    }

    private func prepopulate() {
        if let dish = existingDish {
            dishName = dish.name
            if let mt = dish.cookingModeType, food.availableModes.contains(mt) {
                pickMode(mt)
                if let lt = dish.lastTemperature { temperature = lt }
                if let lw = dish.lastWeight { weight = lw }
                if let ln = dish.level, let config = food.config(for: mt), let levels = config.levels {
                    selectedLevel = levels.first { $0.name == ln }
                }
            }
        } else {
            dishName = food.name
            // Auto-select mode if only one available
            if food.modeConfigs.count == 1 {
                pickMode(food.modeConfigs[0].mode)
            }
        }
    }

    private func confirm() {
        guard let time = computedTime else { return }
        var modeLabel: String?
        if let mode = selectedMode, let config = currentConfig {
            var parts = [mode.rawValue]
            let s = config.parameterSummary(temp: temperature, weight: weight)
            if !s.isEmpty { parts.append(s) }
            modeLabel = parts.joined(separator: " · ")
        }
        let dish = Dish(
            id: existingDish?.id ?? UUID(),
            name: dishName.trimmingCharacters(in: .whitespaces),
            cookingTime: time,
            level: selectedLevel?.name,
            cookingMode: modeLabel,
            cookingModeType: selectedMode,
            foodItemId: food.id,
            lastTemperature: currentConfig?.defaultTemp != nil ? temperature : nil,
            lastWeight: currentConfig?.supportsWeight == true ? weight : nil
        )
        onConfirm(dish)
        dismiss()
    }
}

// MARK: - Sub-components

struct ConfigChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline).fontWeight(.medium)
                .padding(.horizontal, 18).padding(.vertical, 10)
                .background(isSelected ? Color.orange : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(22)
        }
    }
}

struct ConfigParamRow<Control: View>: View {
    let value: String
    let hint: String
    let control: () -> Control

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.headline).foregroundColor(.orange)
                Text(hint).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            control()
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ModeButton: View {
    let mode: CookingModeType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(mode.rawValue)
                .font(.subheadline).fontWeight(.medium)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.orange : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(10)
        }
    }
}

private func formatDuration(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return s > 0 ? "\(m) min \(s) s" : "\(m) min"
}
