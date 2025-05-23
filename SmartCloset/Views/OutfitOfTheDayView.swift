import SwiftUI
import CoreData

struct OutfitOfTheDayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: OutfitSuggestionViewModel
    @State private var showingMoodPicker = false
    @State private var showingWearConfirmation = false
    
    init(viewContext: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: OutfitSuggestionViewModel(context: viewContext))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Today's Suggested Outfit")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.text)
                
                Spacer()
                
                Button(action: { showingMoodPicker = true }) {
                    Text(viewModel.currentMood)
                        .font(Theme.bodyFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: Theme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20)
                }
            }
            .padding(.horizontal)
            
            if viewModel.suggestedOutfit.isEmpty {
                EmptyStateView(
                    systemImage: "tshirt",
                    title: "No Suggestion Yet",
                    message: "Select your mood to get an outfit suggestion",
                    action: { showingMoodPicker = true },
                    actionTitle: "Select Mood"
                )
            } else {
                // Outfit Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(viewModel.suggestedOutfit, id: \.self) { item in
                        ItemCard(item: item)
                    }
                }
                .padding(.horizontal)
                
                // Wear It Button
                Button(action: {
                    showingWearConfirmation = true
                }) {
                    Text("Wear This Outfit")
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
                .padding(.horizontal)
                .confirmationDialog(
                    "Wear This Outfit?",
                    isPresented: $showingWearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Yes, Wear It") {
                        viewModel.wearOutfit(viewModel.suggestedOutfit)
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will update the wear count and last worn date for all items in this outfit.")
                }
            }
        }
        .sheet(isPresented: $showingMoodPicker) {
            MoodPickerSheet(viewModel: viewModel)
        }
        .onAppear {
            suggestOutfitBasedOnTimeAndHistory()
        }
    }
    
    private func suggestOutfitBasedOnTimeAndHistory() {
        let hour = Calendar.current.component(.hour, from: Date())
        let occasion: String
        
        switch hour {
        case 6..<10: occasion = "casual" // Morning
        case 10..<17: occasion = "work" // Work hours
        case 17..<20: occasion = "casual" // Evening
        default: occasion = "cozy" // Night
        }
        
        viewModel.suggestOutfit(for: occasion, mood: viewModel.currentMood)
    }
}

struct ItemCard: View {
    let item: ClosetItem
    
    var body: some View {
        VStack(spacing: 8) {
            if let imageData = item.imageData_,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            
            Text(item.category_ ?? "")
                .font(Theme.bodyFont)
                .foregroundColor(Theme.text)
            
            Text(item.color_ ?? "")
                .font(Theme.captionFont)
                .foregroundColor(Theme.text.opacity(0.7))
        }
        .padding(10)
        .background(Theme.cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

struct MoodPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: OutfitSuggestionViewModel
    
    var body: some View {
        NavigationStack {
            List(viewModel.moodOptions, id: \.self) { mood in
                Button(action: {
                    viewModel.currentMood = mood
                    viewModel.suggestOutfit(for: nil, mood: mood)
                    dismiss()
                }) {
                    HStack {
                        Text(mood)
                            .foregroundColor(Theme.text)
                        
                        Spacer()
                        
                        if mood == viewModel.currentMood {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.primary)
                        }
                    }
                }
            }
            .navigationTitle("Select Your Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primary)
                }
            }
        }
    }
} 