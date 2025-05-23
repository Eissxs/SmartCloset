import SwiftUI

struct ClosetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ClosetViewModel
    
    @State private var selectedCategory: String = "All"
    @State private var searchText: String = ""
    @State private var showingAddItem = false
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 15), count: 2)
    
    init(viewModel: ClosetViewModel? = nil) {
        let vm = viewModel ?? ClosetViewModel(context: PersistenceController.shared.container.viewContext)
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var filteredItems: [ClosetItem] {
        viewModel.items.filter { item in
            let categoryMatch = selectedCategory == "All" || item.category_ == selectedCategory
            let searchMatch = searchText.isEmpty || 
                item.category_?.localizedCaseInsensitiveContains(searchText) == true ||
                item.color_?.localizedCaseInsensitiveContains(searchText) == true
            return categoryMatch && searchMatch
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            CategoryButton(
                                title: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                                viewModel.selectedCategory = category
                                viewModel.fetchItems()
                            }
                        }
                    }
                    .padding()
                }
                
                // Favorites Toggle
                Toggle("Show Favorites Only", isOn: $viewModel.showFavoritesOnly)
                    .padding()
                    .onChange(of: viewModel.showFavoritesOnly) { oldValue, newValue in
                        viewModel.fetchItems()
                    }
                
                ScrollView {
                    VStack {
                        if viewModel.items.isEmpty {
                            EmptyStateView(
                                systemImage: "tshirt.fill",
                                title: "Your Closet is Empty",
                                message: "Start adding your favorite pieces to build your virtual wardrobe",
                                action: { showingAddItem = true },
                                actionTitle: "Add First Item"
                            )
                            .padding(.top, 50)
                        } else if filteredItems.isEmpty {
                            EmptyStateView(
                                systemImage: "tshirt.fill",
                                title: "No Items Found",
                                message: viewModel.showFavoritesOnly ? "No favorite items in this category" : "No items match the selected category or search criteria",
                                action: { 
                                    selectedCategory = "All"
                                    viewModel.selectedCategory = "All"
                                    viewModel.showFavoritesOnly = false
                                    viewModel.fetchItems()
                                },
                                actionTitle: "Show All Items"
                            )
                            .padding(.top, 50)
                        } else {
                            LazyVGrid(columns: columns, spacing: 15) {
                                ForEach(filteredItems, id: \.self) { item in
                                    ClosetItemCard(item: item, viewModel: viewModel)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Closet")
                        .font(Theme.titleFont)
                        .foregroundColor(Theme.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(Theme.primary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search items...")
            .sheet(isPresented: $showingAddItem) {
                AddItemView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.fetchItems()
            }
        }
    }
}

// MARK: - Supporting Views
struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.bodyFont)
                .foregroundColor(isSelected ? .white : Theme.text)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    AnyView(LinearGradient(
                        colors: Theme.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )) :
                    AnyView(Theme.cardBackground)
                )
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        }
    }
}

struct ClosetItemCard: View {
    let item: ClosetItem
    @State private var showingEditSheet = false
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var viewModel: ClosetViewModel
    
    private var isFavorite: Bool {
        item.value(forKey: "favorite_") as? Bool ?? false
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Theme.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 5)
            
            VStack {
                ZStack(alignment: .topTrailing) {
                    if let imageData = item.imageData_,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Favorite Button
                    Button(action: {
                        viewModel.toggleFavorite(item)
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .white)
                            .font(.system(size: 20))
                            .padding(8)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                    .padding(8)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.category_ ?? "")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.text)
                    
                    Text(item.color_ ?? "")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.text.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            }
        }
        .frame(height: 200)
        .contextMenu {
            Button(action: { viewModel.toggleFavorite(item) }) {
                Label(
                    isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: isFavorite ? "heart.slash" : "heart.fill"
                )
            }
            
            Button(action: { showingEditSheet = true }) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: {
                viewModel.deleteItem(item)
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditItemSheet(item: item, viewModel: viewModel)
        }
    }
}

// Add EditItemSheet view
struct EditItemSheet: View {
    let item: ClosetItem
    @ObservedObject var viewModel: ClosetViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: String
    @State private var selectedColor: String
    @State private var isFavorite: Bool
    
    init(item: ClosetItem, viewModel: ClosetViewModel) {
        self.item = item
        self.viewModel = viewModel
        _selectedCategory = State(initialValue: item.category_ ?? viewModel.categories[1])
        _selectedColor = State(initialValue: item.color_ ?? viewModel.colors[1])
        _isFavorite = State(initialValue: item.value(forKey: "favorite_") as? Bool ?? false)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    if let imageData = item.imageData_,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Toggle("Favorite", isOn: Binding(
                        get: { isFavorite },
                        set: { newValue in
                            isFavorite = newValue
                            item.setValue(newValue, forKey: "favorite_")
                            viewModel.saveChanges()
                        }
                    ))
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(viewModel.categories.filter { $0 != "All" }, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    Picker("Color", selection: $selectedColor) {
                        ForEach(viewModel.colors.filter { $0 != "All" }, id: \.self) { color in
                            Text(color).tag(color)
                        }
                    }
                } header: {
                    Text("Item Details")
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.updateItem(item, category: selectedCategory, color: selectedColor)
                        dismiss()
                    }
                }
            }
        }
    }
} 