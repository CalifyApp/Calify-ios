//
//  NotificationManager.swift
//  Calify
//
//  Created by justin lorenzo on 6/23/25.
//

import Foundation
import UserNotifications

struct NotificationManager {
    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted.")
                    scheduleMealReminders()
                } else {
                    print("❌ Notification permission denied.")
                }

                if let error = error {
                    print("Error requesting notification permission: \(error)")
                }
            }
        }
    }
    

    static func scheduleMealReminders() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        guard MealCacheManager.shared.getMeals(for: Date()).isEmpty else {
            return
        }

        let times = [
            (hour: 20, minute: 0, identifier: "dinnerReminder")
        ]

        for time in times {
            let content = UNMutableNotificationContent()
            content.title = "Meal Reminder"
            content.body = "Don’t forget to log your meal!"
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: time.identifier, content: content, trigger: trigger)

            center.add(request) { error in
                if let error = error {
                    print("Error scheduling \(time.identifier): \(error)")
                } else {
                    print("✅ Scheduled \(time.identifier)")
                }
            }
        }
    }
}
