import SwiftUI

// MARK: - Setup state (drives all selections)

private class CookingSetup: ObservableObject {
    @Published var selectedFood: FoodItem?
    @Published var selectedMode: CookingModeType?
    @Published var selectedLevel: CookingLevel?
    @Published var temperature: Int = 180
    @Published var weight: Int = 200

    var currentConfig: ModeConfig? {
        guard let food = selectedFood, let mode = selectedMode else { return nil }
        return food.config(for: mode)
    }

    var computedTime: Int? {
        guard let config = currentConfig else { return nil }
        return config.computeTime(
            level: selectedLevel,
            temp: config.defaultTemp != nil ? temperature : nil,
            weight: config.supportsWeight ? weight : nil
        )
    }

    var modeParamSummary: String {
        currentConfig?.parameterSummary(temp: temperature, weight: weight) ?? ""
    }

    func selectFood(_ food: FoodItem) {
        selectedFood = food
        selectedMode = nil
        selectedLevel = nil
    }

    func selectMode(_ mode: CookingModeType) {
        guard let config = selectedFood?.config(for: mode) else { return }
        selectedMode = mode
        selectedLevel = nil
        temperature = config.defaultTemp ?? 180
        weight = config.defaultWeight ?? 200
    }
}

// MARK: - Main View

struct SimpleCookingView: View {
    @StateObject private var setup = CookingSetup()
    @StateObject private var timerService = TimerService()
    @State private var totalSeconds = 0

    let db = FoodDatabase.shared

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - timerService.remainingSeconds) / Double(totalSeconds)
    }

    var body: some View {
        Group {
            if timerService.isRunning || timerService.isFinished {
                timerRunningView
            } else {
                selectionScrollView
            }
        }
        .navigationTitle("Cuisson Simple")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Selection flow

    private var selectionScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // ── Step 1: Food ──────────────────────────────
                sectionHeader("1. Quel aliment ?", systemImage: "fork.knife")

                ForEach(FoodCategory.allCases) { category in
                    let foods = db.items(for: category)
                    if !foods.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(category.icon) \(category.rawValue)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(foods) { food in
                                        FoodChip(
                                            label: food.name,
                                            isSelected: setup.selectedFood?.id == food.id
                                        ) { setup.selectFood(food) }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }

                // ── Step 2: Mode ──────────────────────────────
                if let food = setup.selectedFood {
                    Divider().padding(.horizontal)
                    sectionHeader("2. Mode de cuisson", systemImage: "flame")

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(food.availableModes) { mode in
                            ModeButton(
                                mode: mode,
                                isSelected: setup.selectedMode == mode
                            ) { setup.selectMode(mode) }
                        }
                    }
                    .padding(.horizontal)
                }

                // ── Step 3: Doneness level ────────────────────
                if let config = setup.currentConfig, let levels = config.levels {
                    Divider().padding(.horizontal)
                    sectionHeader("3. Niveau de cuisson", systemImage: "thermometer.medium")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(levels) { level in
                                FoodChip(
                                    label: level.name,
                                    isSelected: setup.selectedLevel?.id == level.id
                                ) { setup.selectedLevel = level }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // ── Step 4: Temperature & Weight ─────────────
                if let config = setup.currentConfig {
                    let hasTemp   = config.defaultTemp != nil
                    let hasWeight = config.supportsWeight

                    if hasTemp || hasWeight {
                        Divider().padding(.horizontal)
                        sectionHeader(
                            hasTemp && hasWeight ? "4. Température & Poids" :
                            hasTemp ? "4. Température" : "4. Poids",
                            systemImage: "slider.horizontal.3"
                        )

                        VStack(spacing: 16) {
                            if hasTemp, let minT = config.minTemp, let maxT = config.maxTemp {
                                ParameterRow(
                                    label: "Température",
                                    value: "\(setup.temperature) °C",
                                    hint: "\(minT)–\(maxT) °C"
                                ) {
                                    Stepper("", value: $setup.temperature,
                                            in: minT...maxT, step: 10)
                                        .labelsHidden()
                                }
                            }

                            if hasWeight,
                               let minW = config.minWeight,
                               let maxW = config.maxWeight {
                                ParameterRow(
                                    label: "Poids (portion)",
                                    value: "\(setup.weight) g",
                                    hint: "\(minW)–\(maxW) g"
                                ) {
                                    Stepper("", value: $setup.weight,
                                            in: minW...maxW, step: config.weightStep)
                                        .labelsHidden()
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // ── Computed time preview ─────────────────────
                if let seconds = setup.computedTime {
                    Divider().padding(.horizontal)

                    VStack(spacing: 6) {
                        Text("Durée estimée")
                            .font(.subheadline).foregroundColor(.secondary)
                        Text(formatTime(seconds))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        if !setup.modeParamSummary.isEmpty {
                            Text(setup.modeParamSummary)
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                // ── Launch button ─────────────────────────────
                let canLaunch = setup.computedTime != nil &&
                    (setup.currentConfig?.levels == nil || setup.selectedLevel != nil)

                Button(action: launchTimer) {
                    Text("Lancer le timer")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(canLaunch ? Color.orange : Color.gray)
                        .cornerRadius(14)
                        .padding(.horizontal)
                }
                .disabled(!canLaunch)
                .padding(.bottom, 32)
            }
            .padding(.top)
        }
    }

    // MARK: - Timer running

    private var timerRunningView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 14)
                    .frame(width: 250, height: 250)
                Circle()
                    .trim(from: 0, to: timerService.isFinished ? 1 : CGFloat(progress))
                    .stroke(
                        timerService.isFinished ? Color.green : Color.orange,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                VStack(spacing: 6) {
                    if timerService.isFinished {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 52)).foregroundColor(.green)
                        Text("Prêt !").font(.title).fontWeight(.bold)
                    } else {
                        Text(timerService.formattedTime)
                            .font(.system(size: 54, weight: .bold, design: .monospaced))
                        Text("restant").font(.subheadline).foregroundColor(.secondary)
                    }
                }
            }

            VStack(spacing: 4) {
                if let food = setup.selectedFood {
                    Text(food.name).font(.title2).fontWeight(.semibold)
                }
                if let level = setup.selectedLevel {
                    Text(level.name).font(.subheadline).foregroundColor(.secondary)
                }
                if let mode = setup.selectedMode {
                    Label(
                        [mode.rawValue, setup.modeParamSummary]
                            .filter { !$0.isEmpty }.joined(separator: " · "),
                        systemImage: mode.icon
                    )
                    .font(.caption).foregroundColor(.secondary)
                }
            }

            Button(action: { timerService.reset() }) {
                Text(timerService.isFinished ? "Nouveau timer" : "Annuler")
                    .font(.headline)
                    .foregroundColor(timerService.isFinished ? .white : .red)
                    .frame(maxWidth: .infinity).padding()
                    .background(
                        timerService.isFinished ? Color.orange : Color(.secondarySystemBackground)
                    )
                    .cornerRadius(14)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    private func launchTimer() {
        guard let seconds = setup.computedTime else { return }
        totalSeconds = seconds
        let name = setup.selectedFood?.name ?? "Votre plat"
        let level = setup.selectedLevel.map { " (\($0.name))" } ?? ""
        timerService.start(
            seconds: seconds,
            title: "✅ \(name)\(level) est prêt !",
            body: "La cuisson est terminée. Bon appétit !"
        )
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .padding(.horizontal)
    }
}

// MARK: - Reusable Sub-components

struct FoodChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(isSelected ? Color.orange : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct ModeButton: View {
    let mode: CookingModeType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : .orange)
                Text(mode.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.orange : Color(.secondarySystemBackground))
            .cornerRadius(14)
        }
    }
}

struct ParameterRow<Control: View>: View {
    let label: String
    let value: String
    let hint: String
    let control: () -> Control

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.subheadline).fontWeight(.medium)
                Text(hint).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(value)
                .font(.headline).foregroundColor(.orange)
                .frame(width: 80, alignment: .trailing)
            control()
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private func formatTime(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return s > 0 ? "\(m) min \(s) sec" : "\(m) min"
}
