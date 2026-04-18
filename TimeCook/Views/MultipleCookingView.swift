import SwiftUI

struct MultipleCookingView: View {
    @StateObject private var schedule = CookingSchedule()
    @State private var dishes: [Dish] = []
    @State private var showAddDish = false
    @State private var sessionStarted = false

    var body: some View {
        Group {
            if sessionStarted {
                SessionView(schedule: schedule, onStop: stopSession)
            } else if dishes.isEmpty {
                emptyState
            } else {
                dishList
            }
        }
        .navigationTitle("Cuisson Multiple")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !sessionStarted {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddDish = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddDish) {
            AddDishView { dish in dishes.append(dish) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "fork.knife")
                .font(.system(size: 60)).foregroundColor(.gray.opacity(0.4))
            Text("Aucun plat").font(.title2).fontWeight(.semibold)
            Text("Ajoutez vos plats pour synchroniser les cuissons.")
                .foregroundColor(.secondary).multilineTextAlignment(.center)
            Button { showAddDish = true } label: {
                Label("Ajouter un plat", systemImage: "plus.circle.fill")
                    .font(.headline).foregroundColor(.white)
                    .padding(.horizontal, 24).padding(.vertical, 14)
                    .background(Color.orange).cornerRadius(14)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var dishList: some View {
        VStack(spacing: 0) {
            List {
                ForEach(dishes) { dish in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dish.name).font(.headline)
                            Text(dish.formattedTime).font(.subheadline).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "timer").foregroundColor(.orange)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { dishes.remove(atOffsets: $0) }
            }

            VStack(spacing: 12) {
                Button { showAddDish = true } label: {
                    Label("Ajouter un plat", systemImage: "plus")
                        .frame(maxWidth: .infinity).padding()
                        .background(Color(.secondarySystemBackground)).cornerRadius(14)
                }
                Button(action: startSession) {
                    Text("Démarrer la cuisson")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.orange).cornerRadius(14)
                }
            }
            .padding()
        }
    }

    private func startSession() {
        schedule.calculate(dishes: dishes)
        NotificationService.shared.scheduleSession(entries: schedule.entries)
        schedule.isRunning = true
        sessionStarted = true
    }

    private func stopSession() {
        NotificationService.shared.cancelAll()
        schedule.isRunning = false
        sessionStarted = false
    }
}
