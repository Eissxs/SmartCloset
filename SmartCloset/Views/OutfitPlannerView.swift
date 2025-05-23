import SwiftUI
import CoreData

struct OutfitPlannerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: OutfitPlannerViewModel
    @FetchRequest private var calendarSlots: FetchedResults<CalendarSlot>
    @State private var draggedItem: ClosetItem?
    @State private var dragPosition = CGSize.zero
    @State private var isDragging = false
    @State private var draggedItemScale: CGFloat = 1.0
    @State private var draggedItemRotation: Double = 0
    @State private var dropTargetScale: CGFloat = 1.0
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 15), count: 2)
    
    init(viewContext: NSManagedObjectContext) {
        let viewModel = OutfitPlannerViewModel(viewContext: viewContext)
        _viewModel = StateObject(wrappedValue: viewModel)
        let request = viewModel.fetchSlotsForDate(viewModel.selectedDate)
        _calendarSlots = FetchRequest(fetchRequest: request)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    calendarView
                    outfitsList
                }
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Outfit Planner")
                        .font(Theme.titleFont)
                        .foregroundColor(Theme.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            .sheet(isPresented: $viewModel.showingAddEvent) {
                AddEventSheet(
                    date: viewModel.selectedDate,
                    occasion: $viewModel.selectedOccasion,
                    notes: $viewModel.eventNotes,
                    selectedItems: $viewModel.selectedItems,
                    showingClosetPicker: $viewModel.showingClosetPicker,
                    onSave: viewModel.saveEvent
                )
            }
            .onChange(of: viewModel.selectedDate) { oldValue, newValue in
                calendarSlots.nsPredicate = viewModel.fetchSlotsForDate(newValue).predicate
            }
        }
    }
    
    private var calendarView: some View {
        DatePicker(
            "Select Date",
            selection: $viewModel.selectedDate,
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
    
    private var outfitsList: some View {
        Group {
            if calendarSlots.isEmpty {
                Button(action: { viewModel.showingAddEvent = true }) {
                    EmptyStateView(
                        systemImage: "calendar.badge.plus",
                        title: "No Plans Yet",
                        message: "Tap to plan your outfit for this day",
                        actionTitle: "Add Plan"
                    )
                }
            } else {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(calendarSlots) { slot in
                        PlannerSlotView(
                            slot: slot,
                            isTargeted: draggedItem != nil,
                            scale: slot.id_ == viewModel.activeDropTarget?.id_ ? dropTargetScale : 1.0
                        )
                        .onDrop(of: [.text], isTargeted: nil) { providers in
                            guard let provider = providers.first else { return false }
                            
                            provider.loadObject(ofClass: NSString.self) { string, error in
                                if let itemId = string as? String,
                                   let item = try? viewContext.fetch(ClosetItem.fetchRequest()).first(where: { $0.id_?.uuidString == itemId }),
                                   let dropTarget = viewModel.activeDropTarget {
                                    DispatchQueue.main.async {
                                        viewModel.assignOutfit(item, to: dropTarget)
                                        viewModel.activeDropTarget = nil
                                    }
                                }
                            }
                            return true
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var addButton: some View {
        Button(action: { viewModel.showingAddEvent = true }) {
            Image(systemName: "plus")
                .foregroundColor(Theme.primary)
        }
    }
}

// MARK: - Supporting Views
struct PlannedOutfitCard: View {
    let slot: CalendarSlot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            notesSection
            itemsGrid
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
    
    private var header: some View {
        HStack {
            Text(slot.occasion_ ?? "Event")
                .font(.headline)
            
            Spacer()
            
            if let date = slot.date_ {
                Text(date, format: .dateTime.hour().minute())
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.text.opacity(0.7))
            }
        }
    }
    
    private var notesSection: some View {
        Group {
            if let notes = slot.notes_, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var itemsGrid: some View {
        let items = slot.plannedItems_ as? Set<ClosetItem> ?? []
        return Group {
            if !items.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(items)) { item in
                            ItemThumbnail(item: item)
                        }
                    }
                }
            }
        }
    }
}

struct ItemThumbnail: View {
    let item: ClosetItem
    
    var body: some View {
        Group {
            if let imageData = item.imageData_,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct AddEventSheet: View {
    let date: Date
    @Binding var occasion: String
    @Binding var notes: String
    @Binding var selectedItems: [ClosetItem]
    @Binding var showingClosetPicker: Bool
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private let occasions = ["Casual", "Work", "Party", "Date", "Special Event", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                eventDetailsSection
                selectedItemsSection
            }
            .navigationTitle("Plan Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
                }
            }
            .sheet(isPresented: $showingClosetPicker) {
                ClosetPickerView(selectedItems: $selectedItems)
            }
        }
    }
    
    private var eventDetailsSection: some View {
        Section(header: Text("Event Details").foregroundColor(Theme.primary)) {
            Picker("Occasion", selection: $occasion) {
                ForEach(occasions, id: \.self) { occasion in
                    Text(occasion).tag(occasion)
                }
            }
            
            TextEditor(text: $notes)
                .frame(height: 100)
                .placeholder(when: notes.isEmpty) {
                    Text("Add notes about this event...")
                        .foregroundColor(.gray)
                }
        }
    }
    
    private var selectedItemsSection: some View {
        Section(header: Text("Selected Items").foregroundColor(Theme.primary)) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(selectedItems, id: \.self) { item in
                        SelectedItemView(item: item) {
                            if let index = selectedItems.firstIndex(of: item) {
                                selectedItems.remove(at: index)
                            }
                        }
                    }
                    addItemButton
                }
                .padding(.vertical, 5)
            }
        }
    }
    
    private var addItemButton: some View {
        Button(action: { showingClosetPicker = true }) {
            VStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                Text("Add Items")
                    .font(.caption)
            }
            .frame(width: 80, height: 80)
            .foregroundColor(Theme.primary)
            .background(Theme.cardBackground)
            .cornerRadius(8)
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            dismiss()
        }
        .foregroundColor(Theme.primary)
    }
    
    private var saveButton: some View {
        Button("Save") {
            onSave()
            dismiss()
        }
        .foregroundColor(Theme.primary)
    }
}

struct SelectedItemView: View {
    let item: ClosetItem
    let onRemove: () -> Void
    
    var body: some View {
        Group {
            if let imageData = item.imageData_,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        Button(action: onRemove) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .padding(4)
                        }
                        .offset(x: 30, y: -30)
                    )
            }
        }
    }
}

struct ClosetPickerView: View {
    @Binding var selectedItems: [ClosetItem]
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        entity: ClosetItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ClosetItem.category_, ascending: true)]
    ) private var closetItems: FetchedResults<ClosetItem>
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(closetItems, id: \.self) { item in
                    ClosetItemRow(
                        item: item,
                        isSelected: selectedItems.contains(item),
                        onTap: {
                            toggleSelection(for: item)
                        }
                    )
                }
            }
            .navigationTitle("Select Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    doneButton
                }
            }
        }
    }
    
    private var doneButton: some View {
        Button("Done") {
            dismiss()
        }
        .foregroundColor(Theme.primary)
    }
    
    private func toggleSelection(for item: ClosetItem) {
        if let index = selectedItems.firstIndex(of: item) {
            selectedItems.remove(at: index)
        } else {
            selectedItems.append(item)
        }
    }
}

struct ClosetItemRow: View {
    let item: ClosetItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            ItemThumbnail(item: item)
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading) {
                Text(item.category_ ?? "")
                    .font(Theme.bodyFont)
                Text(item.color_ ?? "")
                    .font(Theme.captionFont)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.primary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

struct PlannerSlotView: View {
    let slot: CalendarSlot
    let isTargeted: Bool
    let scale: CGFloat
    @State private var showingDetails = false
    
    var body: some View {
        VStack {
            if let date = slot.date_ {
                Text(date, format: .dateTime.month().day())
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.text)
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.cardBackground)
                    .shadow(radius: isTargeted ? 5 : 2)
                
                if let plannedItems = slot.plannedItems_ as? Set<ClosetItem>,
                   !plannedItems.isEmpty {
                    // Show grid of items
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                        ForEach(Array(plannedItems).prefix(4), id: \.self) { item in
                            if let imageData = item.imageData_,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 65, height: 65)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(8)
                } else {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 30))
                        .foregroundColor(Theme.primary.opacity(0.5))
                }
            }
            .frame(height: 150)
            .scaleEffect(scale)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scale)
            .onLongPressGesture {
                showingDetails = true
            }
            
            if let occasion = slot.occasion_ {
                Text(occasion)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.text)
            }
        }
        .sheet(isPresented: $showingDetails) {
            OutfitDetailsSheet(slot: slot)
        }
    }
}

struct OutfitDetailsSheet: View {
    let slot: CalendarSlot
    @Environment(\.dismiss) private var dismiss
    @State private var showingWearConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date and Occasion
                    VStack(alignment: .leading, spacing: 8) {
                        if let date = slot.date_ {
                            Text(date, format: .dateTime.month().day().year())
                                .font(.title2)
                                .foregroundColor(Theme.text)
                        }
                        
                        Text(slot.occasion_ ?? "No Occasion")
                            .font(.headline)
                            .foregroundColor(Theme.primary)
                    }
                    
                    // Notes
                    if let notes = slot.notes_, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(Theme.text)
                            
                            Text(notes)
                                .font(.body)
                                .foregroundColor(Theme.text.opacity(0.8))
                        }
                        .padding(.vertical)
                    }
                    
                    // Outfit Items
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Outfit Items")
                            .font(.headline)
                            .foregroundColor(Theme.text)
                        
                        if let plannedItems = slot.plannedItems_ as? Set<ClosetItem>,
                           !plannedItems.isEmpty {
                            LazyVGrid(columns: [GridItem(.flexible())], spacing: 15) {
                                ForEach(Array(plannedItems), id: \.self) { item in
                                    ItemAnalyticsCard(item: item)
                                }
                            }
                            
                            // Wear Outfit Button
                            Button(action: {
                                showingWearConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Wear This Outfit")
                                }
                                .font(Theme.bodyFont)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: Theme.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            .padding(.top)
                        } else {
                            Text("No items added yet")
                                .foregroundColor(Theme.text.opacity(0.5))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Outfit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Wear This Outfit?",
                isPresented: $showingWearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Yes, Wear It") {
                    if let items = slot.plannedItems_ as? Set<ClosetItem> {
                        OutfitSuggestionViewModel(context: slot.managedObjectContext!).wearOutfit(Array(items))
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will update the wear count and last worn date for all items in this outfit.")
            }
        }
    }
}

struct ItemAnalyticsCard: View {
    let item: ClosetItem
    
    var lastWornText: String {
        if let lastWorn = item.lastWornDate_ {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: lastWorn, relativeTo: Date())
        }
        return "Never worn"
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Item Image
            if let imageData = item.imageData_,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Item Details and Analytics
            VStack(alignment: .leading, spacing: 8) {
                // Category and Color
                Text(item.category_ ?? "")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.text)
                
                Text(item.color_ ?? "")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.text.opacity(0.7))
                
                // Wear Analytics
                HStack(spacing: 15) {
                    // Times Worn
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Times Worn")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.text.opacity(0.7))
                        Text("\(item.timesWorn_)")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.primary)
                    }
                    
                    // Last Worn
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Worn")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.text.opacity(0.7))
                        Text(lastWornText)
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.text)
                    }
                }
            }
            
            Spacer()
            
            // Favorite Indicator
            if item.value(forKey: "favorite_") as? Bool ?? false {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

struct DraggableItemView: View {
    let item: ClosetItem
    let isDragging: Bool
    @Binding var dragPosition: CGSize
    @Binding var draggedItemScale: CGFloat
    @Binding var draggedItemRotation: Double
    
    var body: some View {
        Group {
            if let imageData = item.imageData_,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: isDragging ? 10 : 2)
                    .scaleEffect(isDragging ? draggedItemScale : 1.0)
                    .rotationEffect(.degrees(isDragging ? draggedItemRotation : 0))
                    .offset(isDragging ? dragPosition : .zero)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isDragging)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if isDragging {
                                    dragPosition = value.translation
                                    // Add elastic effect
                                    let elasticScale = min(1 + abs(value.translation.height) / 500, 1.2)
                                    draggedItemScale = elasticScale
                                    // Add rotation based on horizontal movement
                                    draggedItemRotation = Double(value.translation.width / 20)
                                }
                            }
                            .onEnded { _ in
                                if isDragging {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        dragPosition = .zero
                                        draggedItemScale = 1.0
                                        draggedItemRotation = 0
                                    }
                                }
                            }
                    )
            }
        }
    }
}

struct OutfitDropDelegate: DropDelegate {
    let slot: CalendarSlot
    @Binding var draggedItem: ClosetItem?
    let viewModel: OutfitPlannerViewModel
    @Binding var dropTargetScale: CGFloat
    
    func dropEntered(info: DropInfo) {
        viewModel.activeDropTarget = slot
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            dropTargetScale = 1.1
        }
    }
    
    func dropExited(info: DropInfo) {
        viewModel.activeDropTarget = nil
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            dropTargetScale = 1.0
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = draggedItem else { return false }
        viewModel.assignOutfit(draggedItem, to: slot)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            dropTargetScale = 1.0
        }
        self.draggedItem = nil
        viewModel.activeDropTarget = nil
        return true
    }
}

// MARK: - Helper Extensions
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
} 