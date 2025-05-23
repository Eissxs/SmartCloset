import SwiftUI
import CoreData

class ClosetViewModel: ObservableObject {
    @Published var items: [ClosetItem] = []
    @Published var selectedCategory: String = "All"
    @Published var selectedColor: String = "All"
    @Published var showFavoritesOnly: Bool = false
    private let context: NSManagedObjectContext
    
    let categories = ["All", "Tops", "Bottoms", "Dresses", "Shoes", "Accessories"]
    let colors = ["All", "Black", "White", "Gray", "Navy", "Blue", "Red", "Pink", "Yellow", "Green", "Purple", "Brown", "Orange"]
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchItems()
    }
    
    func fetchItems() {
        let request: NSFetchRequest<ClosetItem> = ClosetItem.fetchRequest()
        var predicates: [NSPredicate] = []
        
        // Add category filter
        if selectedCategory != "All" {
            predicates.append(NSPredicate(format: "category_ == %@", selectedCategory))
        }
        
        // Add color filter
        if selectedColor != "All" {
            predicates.append(NSPredicate(format: "color_ == %@", selectedColor))
        }
        
        // Add favorites filter
        if showFavoritesOnly {
            predicates.append(NSPredicate(format: "favorite_ == YES"))
        }
        
        // Combine predicates if we have any
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        // Sort by last worn date
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClosetItem.lastWornDate_, ascending: true)]
        
        do {
            items = try context.fetch(request)
        } catch {
            print("Error fetching items: \(error)")
        }
    }
    
    func toggleFavorite(_ item: ClosetItem) {
        let currentValue = item.value(forKey: "favorite_") as? Bool ?? false
        item.setValue(!currentValue, forKey: "favorite_")
        saveChanges()
    }
    
    func addItem(image: UIImage, category: String, color: String) {
        let newItem = ClosetItem(context: context)
        newItem.id_ = UUID()
        newItem.imageData_ = image.jpegData(compressionQuality: 0.7)
        newItem.category_ = category
        newItem.color_ = color
        newItem.dateAdded_ = Date()
        newItem.timesWorn_ = 0
        newItem.setValue(false, forKey: "favorite_")
        
        saveChanges()
    }
    
    func deleteItem(_ item: ClosetItem) {
        context.delete(item)
        saveChanges()
    }
    
    func updateItem(_ item: ClosetItem, category: String? = nil, color: String? = nil) {
        if let category = category {
            item.category_ = category
        }
        if let color = color {
            item.color_ = color
        }
        
        saveChanges()
    }
    
    // Save changes to Core Data and refresh items
    func saveChanges() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            DispatchQueue.main.async {
                self.fetchItems()
            }
        } catch {
            print("Error saving context: \(error)")
            // Reset the context if save fails
            context.rollback()
        }
    }
    
    // Statistics
    var itemCountByCategory: [String: Int] {
        Dictionary(grouping: items, by: { $0.category_ ?? "Unknown" })
            .mapValues { $0.count }
    }
    
    var favoriteItems: [ClosetItem] {
        items.filter { item in
            item.value(forKey: "favorite_") as? Bool ?? false
        }
    }
    
    var mostWornItems: [ClosetItem] {
        items.sorted { $0.timesWorn_ > $1.timesWorn_ }
            .prefix(5)
            .map { $0 }
    }
    
    var leastWornItems: [ClosetItem] {
        items.sorted { $0.timesWorn_ < $1.timesWorn_ }
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - Statistics and Analytics
    
    // Get statistics by category
    var categoryStatistics: [(category: String, count: Int, wearCount: Int)] {
        let groupedItems = Dictionary(grouping: items) { $0.category_ ?? "Unknown" }
        return groupedItems.map { category, items in
            let count = items.count
            let totalWears = items.reduce(0) { $0 + Int($1.timesWorn_) }
            return (category: category, count: count, wearCount: totalWears)
        }
        .sorted { $0.wearCount > $1.wearCount }
    }
    
    // Get total wear count
    var totalWearCount: Int {
        items.reduce(0) { $0 + Int($1.timesWorn_) }
    }
    
    // Get average wears per item
    var averageWearsPerItem: Double {
        guard !items.isEmpty else { return 0 }
        return Double(totalWearCount) / Double(items.count)
    }
    
    // Get items that haven't been worn in a while (more than 30 days)
    var unwornItems: [ClosetItem] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return items.filter { item in
            guard let lastWorn = item.lastWornDate_ else { return true }
            return lastWorn < thirtyDaysAgo
        }
    }
    
    // Get most recent outfits
    func fetchRecentOutfits(limit: Int = 5) -> [OutfitEntry] {
        let request: NSFetchRequest<OutfitEntry> = OutfitEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \OutfitEntry.date_, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching recent outfits: \(error)")
            return []
        }
    }
    
    // Get wear frequency by month
    func getWearFrequencyByMonth() -> [(month: String, count: Int)] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        
        let wornDates = items.compactMap { $0.lastWornDate_ }
        let groupedByMonth = Dictionary(grouping: wornDates) { date in
            dateFormatter.string(from: date)
        }
        
        return groupedByMonth.map { month, dates in
            (month: month, count: dates.count)
        }.sorted { $0.month > $1.month }
    }
    
    // Get most popular color combinations
    var popularColorCombinations: [(colors: [String], count: Int)] {
        let outfits = fetchRecentOutfits(limit: 50)
        var combinations: [[String]: Int] = [:]
        
        for outfit in outfits {
            if let items = outfit.items_?.allObjects as? [ClosetItem] {
                let colors = items.compactMap { $0.color_ }
                if colors.count >= 2 {
                    let sortedColors = Array(Set(colors)).sorted()
                    combinations[sortedColors, default: 0] += 1
                }
            }
        }
        
        return combinations.map { colors, count in
            (colors: colors, count: count)
        }.sorted { $0.count > $1.count }
    }
} 