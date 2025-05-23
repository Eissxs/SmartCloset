import SwiftUI
import CoreData

class DiaryViewModel: ObservableObject {
    @Published var entries: [OutfitEntry] = []
    @Published var selectedMood: String = "All"
    private let context: NSManagedObjectContext
    
    let moods = ["All", "Happy", "Confident", "Casual", "Professional", "Cozy", "Glamorous"]
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchEntries()
    }
    
    func fetchEntries() {
        let request: NSFetchRequest<OutfitEntry> = OutfitEntry.fetchRequest()
        
        // Add mood filter if not "All"
        if selectedMood != "All" {
            request.predicate = NSPredicate(format: "mood_ == %@", selectedMood)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \OutfitEntry.date_, ascending: false)]
        
        do {
            entries = try context.fetch(request)
        } catch {
            print("Error fetching diary entries: \(error)")
        }
    }
    
    func addEntry(image: UIImage, mood: String, notes: String, items: [ClosetItem]) {
        let newEntry = OutfitEntry(context: context)
        newEntry.id_ = UUID()
        newEntry.imageData_ = image.jpegData(compressionQuality: 0.7)
        newEntry.mood_ = mood
        newEntry.notes_ = notes
        newEntry.date_ = Date()
        
        // Update worn dates for items
        items.forEach { item in
            item.lastWornDate_ = Date()
            item.timesWorn_ += 1
        }
        
        do {
            try context.save()
            fetchEntries()
        } catch {
            print("Error saving diary entry: \(error)")
        }
    }
    
    func deleteEntry(_ entry: OutfitEntry) {
        context.delete(entry)
        do {
            try context.save()
            fetchEntries()
        } catch {
            print("Error deleting diary entry: \(error)")
        }
    }
    
    func updateEntry(_ entry: OutfitEntry, mood: String? = nil, notes: String? = nil) {
        if let mood = mood {
            entry.mood_ = mood
        }
        if let notes = notes {
            entry.notes_ = notes
        }
        
        do {
            try context.save()
            fetchEntries()
        } catch {
            print("Error updating diary entry: \(error)")
        }
    }
    
    // Statistics and Analysis
    var moodDistribution: [String: Int] {
        Dictionary(grouping: entries, by: { $0.mood_ ?? "Unknown" })
            .mapValues { $0.count }
    }
    
    var entriesByMonth: [Date: [OutfitEntry]] {
        let calendar = Calendar.current
        return Dictionary(grouping: entries) { entry in
            calendar.startOfMonth(for: entry.date_ ?? Date())
        }
    }
}

// Helper extension for date calculations
private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
} 