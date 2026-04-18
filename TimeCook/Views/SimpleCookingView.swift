import SwiftUI

struct SimpleCookingView: View {
    @StateObject private var timerService = TimerService()
    @State private var selectedFood: FoodItem?
    @State private var selectedLevel: CookingLevel?
    @State private var customMinutes = ""
    @State private var useCustom = false
    @State private var totalSeconds = 0

    let foods = FoodDatabase.shared.items

    var cookingTime: Int? {
        if useCustom {
            guard let m = Int(customMinutes), m > 0 else { return nil }
            return m * 60
        }
        if let level = selectedLevel { return level.time }
        return selectedFood?.defaultTime
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - timerService.remainingSeconds) / Double(totalSeconds)
    }

    var body: some View {
        Group {
            if timerService.isRunning || timerService.isFinished {
                timerView
            } else {
                selectionView
            }
        }
        .navigationTitle("Cuisson Simple")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Selection

    private var selectionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Toggle("Temps personnalisé", isOn: $useCustom)
                    .padding(.horizontal)

                if useCustom {
                    HStack {
                        TextField("Minutes", text: $customMinutes)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("min").foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Aliment").font(.headline).padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(foods) { food in
                                    FoodChip(
                                        label: food.name,
                                        isSelected: selectedFood?.id == food.id
                                    ) {
                                        selectedFood = food
                                        selectedLevel = nil
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    if let food = selectedFood, let levels = food.levels {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Niveau de cuisson").font(.headline).padding(.horizontal)
                            HStack(spacing: 10) {
                                ForEach(levels) { level in
                                    FoodChip(
                                        label: level.name,
                                        isSelected: selectedLevel?.id == level.id
                                    ) { selectedLevel = level }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    if let t = cookingTime {
                        Text("\(t / 60) minutes")
                            .font(.title2).fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }

                Button(action: startTimer) {
                    Text("Lancer le timer")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(cookingTime != nil ? Color.orange : Color.gray)
                        .cornerRadius(14)
                        .padding(.horizontal)
                }
                .disabled(cookingTime == nil)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Timer Running

    private var timerView: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 240, height: 240)

                Circle()
                    .trim(from: 0, to: timerService.isFinished ? 1 : CGFloat(progress))
                    .stroke(
                        timerService.isFinished ? Color.green : Color.orange,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                VStack(spacing: 8) {
                    if timerService.isFinished {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48)).foregroundColor(.green)
                        Text("Prêt !").font(.title).fontWeight(.bold)
                    } else {
                        Text(timerService.formattedTime)
                            .font(.system(size: 52, weight: .bold, design: .monospaced))
                        Text("restant").font(.subheadline).foregroundColor(.secondary)
                    }
                }
            }

            if let food = selectedFood {
                Text(food.name).font(.title2).fontWeight(.semibold)
            }

            Button(action: { timerService.reset() }) {
                Text(timerService.isFinished ? "Nouveau timer" : "Annuler")
                    .font(.headline)
                    .foregroundColor(timerService.isFinished ? .white : .red)
                    .frame(maxWidth: .infinity).padding()
                    .background(timerService.isFinished ? Color.orange : Color(.secondarySystemBackground))
                    .cornerRadius(14)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }

    private func startTimer() {
        guard let time = cookingTime else { return }
        totalSeconds = time
        let name = selectedFood?.name ?? "Votre plat"
        timerService.start(
            seconds: time,
            title: "✅ \(name) est prêt !",
            body: "La cuisson est terminée. Bon appétit !"
        )
    }
}

struct FoodChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(isSelected ? Color.orange : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}
