import SwiftUI
import UserNotifications
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var notificationManager = NotificationManager.shared
    
    @AppStorage("dailyReminderHour") private var dailyReminderHour = 8
    @AppStorage("dailyReminderMinute") private var dailyReminderMinute = 0
    @AppStorage("laundryDay") private var laundryDay = 1 // Sunday
    @AppStorage("laundryHour") private var laundryHour = 10
    @AppStorage("eventReminderMinutes") private var eventReminderMinutes = 60
    
    private let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    private let hours = Array(0...23)
    private let minutes = Array(0...59)
    
    var body: some View {
        NavigationView {
            Form {
                // Notifications Section
                Section(header: Text("Notifications").foregroundColor(Theme.primary)) {
                    if !notificationManager.isNotificationsAuthorized {
                        Button("Enable Notifications") {
                            notificationManager.requestAuthorization()
                        }
                        .foregroundColor(Theme.primary)
                    }
                    
                    // Daily Outfit Reminder
                    VStack(alignment: .leading) {
                        Text("Daily Outfit Reminder")
                            .font(Theme.bodyFont)
                        HStack {
                            Picker("Hour", selection: $dailyReminderHour) {
                                ForEach(hours, id: \.self) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            Text(":")
                            
                            Picker("Minute", selection: $dailyReminderMinute) {
                                ForEach(minutes, id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                        }
                    }
                    
                    // Laundry Reminder
                    VStack(alignment: .leading) {
                        Text("Laundry Reminder")
                            .font(Theme.bodyFont)
                        HStack {
                            Picker("Day", selection: $laundryDay) {
                                ForEach(0..<weekdays.count, id: \.self) { index in
                                    Text(weekdays[index]).tag(index + 1)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Picker("Hour", selection: $laundryHour) {
                                ForEach(hours, id: \.self) { hour in
                                    Text("\(hour):00").tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    
                    // Event Reminder
                    VStack(alignment: .leading) {
                        Text("Event Reminder Default")
                            .font(Theme.bodyFont)
                        Picker("Minutes Before", selection: $eventReminderMinutes) {
                            Text("30 minutes").tag(30)
                            Text("1 hour").tag(60)
                            Text("2 hours").tag(120)
                            Text("1 day").tag(1440)
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // Data Management
                Section(header: Text("Data Management").foregroundColor(Theme.primary)) {
                    Button(role: .destructive) {
                        resetCloset()
                    } label: {
                        Label("Reset Closet", systemImage: "trash")
                    }
                }
                
                // About
                Section(header: Text("About").foregroundColor(Theme.primary)) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .onChange(of: dailyReminderHour) { oldValue, newValue in updateNotifications() }
            .onChange(of: dailyReminderMinute) { oldValue, newValue in updateNotifications() }
            .onChange(of: laundryDay) { oldValue, newValue in updateNotifications() }
            .onChange(of: laundryHour) { oldValue, newValue in updateNotifications() }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(Theme.titleFont)
                        .foregroundColor(Theme.primary)
                }
            }
        }
    }
    
    private func updateNotifications() {
        guard notificationManager.isNotificationsAuthorized else { return }
        
        // Cancel existing notifications
        notificationManager.cancelAllNotifications()
        
        // Reschedule with new times
        notificationManager.scheduleDailyOutfitReminder(
            at: dailyReminderHour,
            minute: dailyReminderMinute
        )
        
        notificationManager.scheduleLaundryReminder(
            weekday: laundryDay,
            hour: laundryHour
        )
    }
    
    private func resetCloset() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ClosetItem.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(batchDeleteRequest)
            try viewContext.save()
        } catch {
            print("Error resetting closet: \(error)")
        }
    }
}

// MARK: - Laundry Reminder View
struct LaundryReminderView: View {
    let weekdays: [String]
    @Binding var selectedDay: Int
    @Binding var selectedHour: Int
    
    var body: some View {
        Form {
            Section {
                Picker("Day of Week", selection: $selectedDay) {
                    ForEach(Array(weekdays.enumerated()), id: \.offset) { index, day in
                        Text(day).tag(index + 1)
                    }
                }
                
                Picker("Time", selection: $selectedHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(String(format: "%02d:00", hour)).tag(hour)
                    }
                }
            } header: {
                Text("Laundry Reminder Schedule")
                    .foregroundColor(Theme.primary)
            }
        }
        .onChange(of: selectedDay) { oldValue, newValue in updateLaundryReminder() }
        .onChange(of: selectedHour) { oldValue, newValue in updateLaundryReminder() }
        .navigationTitle("Laundry Reminder")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func updateLaundryReminder() {
        NotificationManager.shared.scheduleLaundryReminder(
            weekday: selectedDay,
            hour: selectedHour
        )
    }
} 