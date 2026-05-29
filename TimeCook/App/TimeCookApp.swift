import SwiftUI
import UserNotifications

@main
struct TimeCookApp: App {
    @StateObject private var store = CookingStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .task {
                    await NotificationScheduler.shared.requestAuthorizationIfNeeded()
                }
        }
    }
}
