import Foundation
import UserNotifications

// FIX: Uses UNTimeIntervalNotificationTrigger — scheduled by the OS so notifications
// fire even when the app is in background or the screen is locked.
class NotificationService {
    static let shared = NotificationService()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, error in
            if let error { print("Notification permission error: \(error)") }
        }
    }

    func schedule(identifier: String, title: String, body: String, after seconds: TimeInterval) {
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, seconds),
            repeats: false
        )
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Schedule notification error: \(error)") }
        }
    }

    func cancel(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func scheduleSession(entries: [ScheduleEntry]) {
        cancelAll()
        let now = Date()

        for entry in entries {
            let delayToStart = entry.startTime.timeIntervalSince(now)
            if delayToStart >= 0 {
                schedule(
                    identifier: "start_\(entry.notificationId)",
                    title: "🍳 Lancez \(entry.dish.name) !",
                    body: "Il est temps de commencer la cuisson.",
                    after: delayToStart
                )
            }

            let delayToEnd = entry.endTime.timeIntervalSince(now)
            if delayToEnd >= 0 {
                schedule(
                    identifier: "end_\(entry.notificationId)",
                    title: "✅ \(entry.dish.name) est prêt !",
                    body: "La cuisson est terminée. Bon appétit !",
                    after: delayToEnd
                )
            }
        }

        if let lastEndTime = entries.last?.endTime {
            let delay = lastEndTime.timeIntervalSince(now)
            if delay >= 0 {
                schedule(
                    identifier: "all_ready",
                    title: "🎉 Tous les plats sont prêts !",
                    body: "Votre repas est prêt à être servi.",
                    after: delay + 2
                )
            }
        }
    }
}
