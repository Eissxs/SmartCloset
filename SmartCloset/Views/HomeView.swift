import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ClosetViewModel
    @State private var showingAddItem = false
    @State private var selectedStatistic: StatisticType = .overview
    
    enum StatisticType: String, CaseIterable {
        case overview = "Overview"
        case mostWorn = "Most Worn"
        case categories = "Categories"
        case colors = "Colors"
    }
    
    init() {
        let vm = ClosetViewModel(context: PersistenceController.shared.container.viewContext)
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    if viewModel.items.isEmpty {
                        EmptyStateView(
                            systemImage: "tshirt",
                            title: "Welcome to SmartCloset",
                            message: "Start by adding some clothes to your virtual closet!",
                            action: { showingAddItem = true },
                            actionTitle: "Add First Item"
                        )
                        .padding()
                    } else {
                        // Outfit of the Day Section
                        OutfitOfTheDayView(viewContext: viewContext)
                            .padding(.top, 10)
                        
                        // Statistics Type Picker
                        Picker("Statistics", selection: $selectedStatistic) {
                            ForEach(StatisticType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Statistics Section
                        VStack(alignment: .leading, spacing: 15) {
                            switch selectedStatistic {
                            case .overview:
                                overviewStats
                            case .mostWorn:
                                mostWornStats
                            case .categories:
                                categoryStats
                            case .colors:
                                colorStats
                            }
                        }
                        
                        // Recently Added Section
                        recentlyAddedSection
                    }
                }
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SmartCloset")
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
            .sheet(isPresented: $showingAddItem) {
                AddItemView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.fetchItems()
            }
        }
    }
    
    // MARK: - Statistics Views
    
    private var overviewStats: some View {
        VStack(spacing: 15) {
            Text("Closet Overview")
                .font(Theme.titleFont)
                .foregroundColor(Theme.text)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    StatCard(
                        icon: "tshirt.fill",
                        title: "Total Items",
                        value: "\(viewModel.items.count)"
                    )
                    
                    StatCard(
                        icon: "number",
                        title: "Total Wears",
                        value: "\(viewModel.totalWearCount)"
                    )
                    
                    StatCard(
                        icon: "chart.bar.fill",
                        title: "Avg Wears",
                        value: String(format: "%.1f", viewModel.averageWearsPerItem)
                    )
                    
                    StatCard(
                        icon: "exclamationmark.circle.fill",
                        title: "Unworn 30d",
                        value: "\(viewModel.unwornItems.count)"
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var mostWornStats: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Most Worn Items")
                .font(Theme.titleFont)
                .foregroundColor(Theme.text)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.mostWornItems, id: \.self) { item in
                        VStack {
                            if let imageData = item.imageData_,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Text("\(item.timesWorn_) wears")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.text)
                        }
                        .frame(width: 100)
                        .padding(8)
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var categoryStats: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Category Statistics")
                .font(Theme.titleFont)
                .foregroundColor(Theme.text)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.categoryStatistics, id: \.category) { stat in
                        VStack(spacing: 8) {
                            Text(stat.category)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.text)
                            
                            Text("\(stat.count) items")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.text.opacity(0.7))
                            
                            Text("\(stat.wearCount) wears")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.primary)
                        }
                        .frame(width: 120)
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(15)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var colorStats: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Popular Color Combinations")
                .font(Theme.titleFont)
                .foregroundColor(Theme.text)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.popularColorCombinations.prefix(5), id: \.colors) { combo in
                        VStack(spacing: 8) {
                            ForEach(combo.colors, id: \.self) { color in
                                Text(color)
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.text)
                            }
                            
                            Text("\(combo.count) outfits")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.primary)
                        }
                        .frame(width: 120)
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(15)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var recentlyAddedSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recently Added")
                .font(Theme.titleFont)
                .foregroundColor(Theme.text)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(Array(viewModel.items.prefix(5))) { item in
                        RecentItemCard(item: item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Theme.primary)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.primary)
            
            Text(title)
                .font(Theme.captionFont)
                .foregroundColor(Theme.text)
        }
        .frame(width: 120)
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

struct RecentItemCard: View {
    let item: ClosetItem
    
    var body: some View {
        VStack(spacing: 8) {
            if let imageData = item.imageData_,
               let uiImage = UIImage(data: imageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    if item.value(forKey: "favorite_") as? Bool ?? false {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 16))
                            .padding(4)
                            .background(Circle().fill(Color.white))
                            .padding(4)
                    }
                }
            }
            
            VStack(spacing: 4) {
                Text(item.category_ ?? "")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                
                Text("\(item.timesWorn_) wears")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.text.opacity(0.7))
            }
        }
        .frame(width: 100)
        .padding(8)
        .background(Theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
} 