import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.orange)
                    Text("TimeCook")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Synchronisez vos cuissons")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 48)

                VStack(spacing: 16) {
                    NavigationLink(destination: SimpleCookingView()) {
                        MenuCard(
                            title: "Cuisson Simple",
                            subtitle: "Timer pour un seul plat",
                            icon: "timer",
                            color: .blue
                        )
                    }
                    NavigationLink(destination: MultipleCookingView()) {
                        MenuCard(
                            title: "Cuisson Multiple",
                            subtitle: "Synchroniser plusieurs plats",
                            icon: "rectangle.stack.fill",
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

struct MenuCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(.white)
                .frame(width: 54, height: 54)
                .background(color)
                .cornerRadius(14)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}
