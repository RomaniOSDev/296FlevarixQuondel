import Foundation
import UserNotifications

enum NotificationService {
    private static let reminderKey = "reminder_enabled"
    private static let identifier = "daily_craft_reminder"

    static var reminderEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: reminderKey) == nil { return false }
            return UserDefaults.standard.bool(forKey: reminderKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: reminderKey)
            if newValue {
                scheduleReminder()
            } else {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            }
        }
    }

    static func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            center.removePendingNotificationRequests(withIdentifiers: [identifier])

            let content = UNMutableNotificationContent()
            content.title = "Design Session"
            content.body = "Spend a few minutes crafting a new texture today."
            content.sound = HapticService.soundEnabled ? .default : nil

            var date = DateComponents()
            date.hour = 10
            date.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request)
        }
    }
}
