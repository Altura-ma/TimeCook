import SwiftUI

struct MultipleCookingView: View {
    @EnvironmentObject var session: CookingSessionManager
    @State private var selectedFood: FoodItem? = nil
    @State private var editingDish: Dish? = nil
    @State private var showDishList = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if session.isSessionActive {
                    SessionView(
                        schedule: session.schedule,
                        onStop: { session.stopSession() }
                    )
                } else {
                    FoodGridView { food in selectedFood = food }
                }
            }

            // ── Bottom bar (always visible when not in session) ──
            if !session.isSessionActive {
                bottomBar
            }
        }
        .navigationTitle("Cuisson Multiple")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedFood) { food in
            DishConfigSheet(
                food: food,
                context: .addToList,
                onConfirm: { dish in session.addDish(dish) }
            )
        }
        .sheet(item: $editingDish) { dish in
            editSheet(for: dish)
        }
        .sheet(isPresented: $showDishList) {
            dishListSheet
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 14) {
            // Dish count bubble
            Button { showDishList = true } label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 32, height: 32)
                        Text("\(session.pendingDishes.count)")
                            .font(.subheadline).fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(session.pendingDishes.isEmpty
                             ? "Aucun plat"
                             : "\(session.pendingDishes.count) plat\(session.pendingDishes.count > 1 ? "s" : "") ajouté\(session.pendingDishes.count > 1 ? "s" : "")")
                            .font(.subheadline).fontWeight(.semibold)
                        if !session.pendingDishes.isEmpty {
                            Text("Voir la liste →").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .foregroundColor(.primary)

            Spacer()

            // Start button
            Button(action: { session.startSession() }) {
                Label("Démarrer", systemImage: "play.fill")
                    .font(.headline).foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(session.pendingDishes.isEmpty ? Color.gray : Color.orange)
                    .cornerRadius(24)
            }
            .disabled(session.pendingDishes.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(.gray.opacity(0.3)), alignment: .top)
    }

    // MARK: - Dish list sheet

    private var dishListSheet: some View {
        NavigationView {
            Group {
                if session.pendingDishes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife").font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("Aucun plat ajouté").font(.title3).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(session.pendingDishes) { dish in
                            Button { editingDish = dish; showDishList = false } label: {
                                DishListRow(dish: dish)
                            }
                            .tint(.primary)
                        }
                        .onDelete { session.removeDish(at: $0) }
                    }
                }
            }
            .navigationTitle("Plats en attente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { showDishList = false }
                }
                ToolbarItem(placement: .destructiveAction) {
                    if !session.pendingDishes.isEmpty {
                        Button("Tout effacer") { session.clearDishes() }
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }

    // MARK: - Edit sheet

    @ViewBuilder
    private func editSheet(for dish: Dish) -> some View {
        if let foodId = dish.foodItemId,
           let food = FoodDatabase.shared.items.first(where: { $0.id == foodId }) {
            DishConfigSheet(
                food: food,
                context: .editInList,
                existingDish: dish,
                onConfirm: { updated in session.updateDish(updated) }
            )
        } else {
            // Fallback: manual edit form for dishes without a food reference
            ManualEditSheet(dish: dish) { updated in session.updateDish(updated) }
        }
    }
}

// MARK: - Dish list row

struct DishListRow: View {
    let dish: Dish

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(dish.name).font(.headline)
                HStack(spacing: 4) {
                    Text(dish.formattedTime).foregroundColor(.orange)
                    if let mode = dish.cookingMode {
                        Text("·").foregroundColor(.secondary)
                        Text(mode).foregroundColor(.secondary)
                    }
                }
                .font(.caption)
            }
            Spacer()
            Image(systemName: "pencil.circle")
                .foregroundColor(.orange).font(.title3)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Manual edit fallback

struct ManualEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let dish: Dish
    let onSave: (Dish) -> Void

    @State private var name: String = ""
    @State private var minutes: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Nom") { TextField("Nom", text: $name) }
                Section("Durée") {
                    HStack {
                        TextField("Minutes", text: $minutes).keyboardType(.numberPad)
                        Text("min").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Modifier le plat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        guard let m = Int(minutes), m > 0 else { return }
                        var updated = dish
                        updated.name = name
                        updated.cookingTime = m * 60
                        onSave(updated)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            name = dish.name
            minutes = "\(dish.cookingTime / 60)"
        }
    }
}
