import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var isNotificationsAuthorized = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Notification Types
    enum NotificationType {
        case dailyOutfitReminder
        case laundryReminder
        case eventOutfitReminder(date: Date, eventName: String)
        
        var identifier: String {
            switch self {
            case .dailyOutfitReminder:
                return "dailyOutfitReminder"
            case .laundryReminder:
                return "laundryReminder"
            case .eventOutfitReminder:
                return "eventOutfitReminder"
            }
        }
        
        var title: String {
            switch self {
            case .dailyOutfitReminder:
                return "Time to Plan Your Outfit! 👗"
            case .laundryReminder:
                return "Laundry Day Reminder 🧺"
            case .eventOutfitReminder(_, let eventName):
                return "Outfit Planning: \(eventName) 📅"
            }
        }
        
        var body: String {
            switch self {
            case .dailyOutfitReminder:
                return "Get ready to look fabulous today! 💖"
            case .laundryReminder:
                return "Time to refresh your wardrobe! Don't forget to check your laundry basket."
            case .eventOutfitReminder:
                return "Plan your perfect outfit for the upcoming event!"
            }
        }
    }
    
    // MARK: - Permission Management
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isNotificationsAuthorized = granted
            }
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleDailyOutfitReminder(at hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Plan Your Outfit! 👗"
        content.body = "Time to choose your perfect look for today!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyOutfit", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleLaundryReminder(weekday: Int, hour: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Laundry Day! 🧺"
        content.body = "Time to refresh your wardrobe!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = weekday // 1 = Sunday, 2 = Monday, etc.
        dateComponents.hour = hour
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "laundryDay", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleEventReminder(for event: CalendarSlot, minutesBefore: Int = 60) {
        let content = UNMutableNotificationContent()
        content.title = "Event Coming Up! ✨"
        content.body = "Prepare your outfit for: \(event.occasion_ ?? "your event")"
        content.sound = .default
        
        let reminderDate = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: event.date_!)!
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "event-\(event.id_?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Managing Notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func cancelNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
} 