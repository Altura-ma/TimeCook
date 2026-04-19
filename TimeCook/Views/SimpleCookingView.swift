import SwiftUI

struct SimpleCookingView: View {
    @StateObject private var timerService = TimerService()
    @State private var selectedFood: FoodItem? = nil
    @State private var activeDish: Dish? = nil    // dish being cooked
    @State private var totalSeconds = 0

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - timerService.remainingSeconds) / Double(totalSeconds)
    }

    var body: some View {
        Group {
            if timerService.isRunning || timerService.isFinished {
                timerView
            } else {
                FoodGridView { food in selectedFood = food }
            }
        }
        .navigationTitle("Cuisson Simple")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedFood) { food in
            DishConfigSheet(
                food: food,
                context: .simpleTimer,
                onConfirm: { dish in
                    activeDish = dish
                    totalSeconds = dish.cookingTime
                    timerService.start(
                        seconds: dish.cookingTime,
                        title: "✅ \(dish.name) est prêt !",
                        body: "La cuisson est terminée. Bon appétit !"
                    )
                }
            )
        }
    }

    // MARK: - Timer display

    private var timerView: some View {
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

            if let dish = activeDish {
                VStack(spacing: 4) {
                    Text(dish.name).font(.title2).fontWeight(.semibold)
                    if let level = dish.level {
                        Text(level).font(.subheadline).foregroundColor(.secondary)
                    }
                    if let mode = dish.cookingMode {
                        Label(mode, systemImage: dish.cookingModeType?.icon ?? "flame.fill")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }

            Button(action: {
                timerService.reset()
                activeDish = nil
            }) {
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
}
