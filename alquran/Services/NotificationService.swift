import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        let granted = try await center.requestAuthorization(options: options)
        AppLogger.info("Notifications authorization granted: \(granted)")
    }

    func scheduleDailyReminder(at hour: Int = 20, minute: Int = 0) {
        Task {
            do {
                try await requestAuthorization()
                try await scheduleNotification(
                    identifier: "dailyQuranReminder",
                    title: "Time for Quran reflection",
                    body: "Open Quran Companion for your daily reading and verse of the day.",
                    hour: hour,
                    minute: minute
                )
            } catch {
                AppLogger.warning("Unable to schedule daily reminder: \(error)")
            }
        }
    }

    func scheduleQuranReadingReminder(at hour: Int = 18, minute: Int = 30) {
        Task {
            do {
                try await requestAuthorization()
                try await scheduleNotification(
                    identifier: "dailyReadingReminder",
                    title: "Continue your reading",
                    body: "Resume your Quran journey with today's verse and bookmark.",
                    hour: hour,
                    minute: minute
                )
            } catch {
                AppLogger.warning("Unable to schedule reading reminder: \(error)")
            }
        }
    }

    private func scheduleNotification(identifier: String, title: String, body: String, hour: Int, minute: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await center.add(request)
        AppLogger.info("Scheduled notification \(identifier) at \(hour):\(minute)")
    }

    func cancelDailyReminder() {
        let identifiers = ["dailyQuranReminder", "dailyReadingReminder"]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        AppLogger.info("Canceled daily Quran reminders")
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        AppLogger.info("Canceled all notifications")
    }
}
