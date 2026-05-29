import Foundation
import UserNotifications
import TimeCookCore

@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private init() {}

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func schedule(plan: CookingPlan, startDate: Date) async throws {
        cancelCookingNotifications()
        let notifications = NotificationPlanBuilder.notifications(for: plan)
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            guard granted else { throw NotificationError.permissionDenied }
        } else if settings.authorizationStatus == .denied {
            throw NotificationError.permissionDenied
        }

        for item in notifications {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, item.fireOffset), repeats: false)
            try await center.add(UNNotificationRequest(identifier: item.id, content: content, trigger: trigger))
        }
    }

    func cancelCookingNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(NotificationPlanBuilder.namespace) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    enum NotificationError: LocalizedError {
        case permissionDenied
        var errorDescription: String? {
            "Les notifications sont désactivées. Active-les dans Réglages pour recevoir les alertes de cuisson."
        }
    }
}
