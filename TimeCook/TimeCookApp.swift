import SwiftUI

@main
struct TimeCookApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var sessionManager = CookingSessionManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(sessionManager)
        }
    }
}
