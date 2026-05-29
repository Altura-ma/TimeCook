import SwiftUI
import TimeCookCore

struct ContentView: View {
    @EnvironmentObject private var store: CookingStore
    @State private var dishName = ""
    @State private var minutes = 10.0

    var body: some View {
        NavigationView {
            List {
                Section("Ajouter un plat") {
                    TextField("Nom du plat", text: $dishName)
                    Stepper(value: $minutes, in: 1...240, step: 1) {
                        Text("Durée : \(Int(minutes)) min")
                    }
                    Button("Ajouter") {
                        store.addDish(name: dishName, minutes: minutes)
                        dishName = ""
                    }
                    .disabled(dishName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("Plats") {
                    if store.dishes.isEmpty {
                        Text("Ajoute au moins un plat pour créer un planning.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.dishes) { dish in
                        HStack {
                            Text(dish.name)
                            Spacer()
                            Text(CookingPlanFormatter.clock(dish.duration))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: store.deleteDish)
                }

                Section("Planning synchronisé") {
                    ForEach(store.plan.steps) { step in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.dish.name).font(.headline)
                            Text(step.startOffset == 0 ? "À lancer tout de suite" : "À lancer après \(CookingPlanFormatter.clock(step.startOffset))")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("Tout sera prêt dans \(CookingPlanFormatter.clock(store.plan.totalDuration)).")
                        .font(.subheadline.weight(.semibold))
                }

                if let message = store.errorMessage {
                    Section {
                        Text(message).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Time Cook")
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    if store.isCooking {
                        Button(role: .destructive) {
                            Task { await store.stopCooking() }
                        } label: {
                            Label("Arrêter la cuisson", systemImage: "stop.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button {
                            Task { await store.startCooking() }
                        } label: {
                            Label("Lancer les notifications", systemImage: "timer")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(store.plan.totalDuration <= 0)
                    }
                }
                .padding()
                .background(.thinMaterial)
            }
        }
    }
}

#Preview {
    ContentView().environmentObject(CookingStore())
}
