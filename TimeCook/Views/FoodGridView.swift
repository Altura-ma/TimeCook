import SwiftUI

// MARK: - Food Grid (mosaic)

struct FoodGridView: View {
    let onSelect: (FoodItem) -> Void
    @State private var selectedCategory: FoodCategory? = nil
    @State private var searchText = ""

    private let db = FoodDatabase.shared
    private let columns = [GridItem(.adaptive(minimum: 96, maximum: 130), spacing: 12)]

    private var displayedFoods: [FoodItem] {
        let base = selectedCategory.map { db.items(for: $0) } ?? db.items
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Search bar ──────────────────────────────────
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Rechercher un aliment…", text: $searchText)
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 8)

            // ── Category filter chips ────────────────────────
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryFilterChip(label: "Tous", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    ForEach(FoodCategory.allCases) { cat in
                        CategoryFilterChip(
                            label: cat.icon + " " + cat.rawValue,
                            isSelected: selectedCategory == cat
                        ) { selectedCategory = cat }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }

            // ── Food mosaic grid ─────────────────────────────
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(displayedFoods) { food in
                        FoodTile(food: food) { onSelect(food) }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100) // space for bottom bar
            }
        }
    }
}

// MARK: - Food Tile

struct FoodTile: View {
    let food: FoodItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(food.category.icon)
                    .font(.system(size: 30))
                Text(food.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .padding(8)
            .background(Color(hex: food.category.colorHex).opacity(0.15))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: food.category.colorHex).opacity(0.3), lineWidth: 1)
            )
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Category filter chip

struct CategoryFilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption).fontWeight(.medium)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(isSelected ? Color.orange : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Color from hex helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
