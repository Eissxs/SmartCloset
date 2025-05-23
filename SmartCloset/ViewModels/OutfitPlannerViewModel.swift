import SwiftUI
import CoreData

class OutfitPlannerViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext
    @Published var selectedDate = Date()
    @Published var showingAddEvent = false
    @Published var selectedOccasion = ""
    @Published var eventNotes = ""
    @Published var showingClosetPicker = false
    @Published var selectedItems: [ClosetItem] = []
    @Published var activeDropTarget: CalendarSlot?
    
    let occasions = ["Casual", "Work", "Party", "Date", "Special Event", "Other"]
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func saveEvent() {
        withAnimation {
            let newSlot = CalendarSlot(context: viewContext)
            newSlot.date_ = selectedDate
            newSlot.occasion_ = selectedOccasion
            newSlot.notes_ = eventNotes
            newSlot.id_ = UUID()
            
            selectedItems.forEach { item in
                newSlot.addToPlannedItems_(item)
            }
            
            do {
                try viewContext.save()
                resetForm()
            } catch {
                print("Error saving calendar slot: \(error)")
            }
        }
    }
    
    func resetForm() {
        selectedOccasion = ""
        eventNotes = ""
        selectedItems.removeAll()
    }
    
    func fetchSlotsForDate(_ date: Date) -> NSFetchRequest<CalendarSlot> {
        let request = CalendarSlot.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "date_ >= %@ AND date_ < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CalendarSlot.date_, ascending: true)]
        
        return request
    }
    
    func assignOutfit(_ item: ClosetItem, to slot: CalendarSlot) {
        slot.addToPlannedItems_(item)
        
        do {
            try viewContext.save()
        } catch {
            print("Error assigning outfit: \(error)")
        }
    }
} 