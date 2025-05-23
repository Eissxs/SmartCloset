import SwiftUI
import CoreData

class OutfitSuggestionViewModel: ObservableObject {
    @Published var suggestedOutfit: [ClosetItem] = []
    @Published var currentMood: String = "Happy"
    private let context: NSManagedObjectContext
    
    // Constants
    let moodOptions = ["Happy", "Professional", "Casual", "Glamorous", "Cozy"]
    let categories = ["Tops", "Bottoms", "Shoes", "Accessories"]
    
    // Category mappings
    private let occasionCategories: [String: [String]] = [
        "work": ["Blazer", "Blouse", "Dress Pants", "Pencil Skirt", "Dress Shoes", "Heels"],
        "casual": ["T-Shirt", "Jeans", "Sneakers", "Casual Dress", "Sandals"],
        "formal": ["Dress", "Suit", "Heels", "Formal Wear"],
        "cozy": ["Sweater", "Hoodie", "Sweatpants", "Lounge Wear"]
    ]
    
    private let moodColors: [String: [String]] = [
        "happy": ["Yellow", "Pink", "Orange", "Bright"],
        "professional": ["Black", "Navy", "Gray", "White"],
        "casual": ["Blue", "Green", "Brown", "Gray"],
        "glamorous": ["Red", "Gold", "Silver", "Purple"],
        "cozy": ["Beige", "Brown", "Gray", "Cream"]
    ]
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func suggestOutfit(for occasion: String? = nil, mood: String? = nil) {
        let fetchRequest: NSFetchRequest<ClosetItem> = ClosetItem.fetchRequest()
        var predicates: [NSPredicate] = []
        
        // Get appropriate categories based on occasion
        if let occasion = occasion?.lowercased(),
           let categories = occasionCategories[occasion] {
            predicates.append(NSPredicate(format: "category_ IN %@", categories))
        }
        
        // Get appropriate colors based on mood
        if let mood = mood?.lowercased(),
           let colors = moodColors[mood] {
            predicates.append(NSPredicate(format: "color_ IN %@", colors))
        }
        
        // Combine predicates if we have any
        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        }
        
        do {
            let items = try context.fetch(fetchRequest)
            suggestedOutfit = createBalancedOutfit(from: items)
        } catch {
            print("Error fetching items for suggestion: \(error)")
        }
    }
    
    private func createBalancedOutfit(from items: [ClosetItem]) -> [ClosetItem] {
        var outfit: [ClosetItem] = []
        
        // Try to select one item from each main category
        for category in categories {
            let categoryItems = items.filter { item in
                let itemCategory = item.category_?.lowercased() ?? ""
                return itemCategory.contains(category.lowercased())
            }
            
            if let selectedItem = categoryItems.randomElement() {
                outfit.append(selectedItem)
            }
        }
        
        return outfit
    }
    
    // Update last worn date for selected outfit
    func wearOutfit(_ items: [ClosetItem]) {
        let today = Date()
        items.forEach { item in
            item.lastWornDate_ = today
            item.timesWorn_ += 1
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving worn date: \(error)")
        }
    }
} 