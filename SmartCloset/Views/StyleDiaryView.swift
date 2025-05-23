import SwiftUI
import PhotosUI

struct StyleDiaryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: DiaryViewModel
    
    @State private var showingAddEntry = false
    @State private var selectedImage: UIImage?
    @State private var selectedMood = "Happy"
    @State private var notes = ""
    
    init() {
        let vm = DiaryViewModel(context: PersistenceController.shared.container.viewContext)
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Mood Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.moods, id: \.self) { mood in
                                MoodChip(
                                    mood: mood,
                                    isSelected: mood == viewModel.selectedMood,
                                    action: {
                                        viewModel.selectedMood = mood
                                        viewModel.fetchEntries()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if viewModel.entries.isEmpty {
                        EmptyStateView(
                            systemImage: "book.fill",
                            title: viewModel.selectedMood == "All" ? "Your Style Diary is Empty" : "No Entries Found",
                            message: viewModel.selectedMood == "All" ? 
                                "Start logging your daily outfits and track your style journey!" :
                                "No entries found with the selected mood filter",
                            action: { 
                                if viewModel.selectedMood != "All" {
                                    viewModel.selectedMood = "All"
                                    viewModel.fetchEntries()
                                } else {
                                    showingAddEntry = true
                                }
                            },
                            actionTitle: viewModel.selectedMood == "All" ? "Add First Entry" : "Show All Entries"
                        )
                    } else {
                        // Diary Entries Grid
                        LazyVStack(spacing: 15) {
                            ForEach(viewModel.entries, id: \.self) { entry in
                                DiaryEntryCard(entry: entry)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Style Diary")
                        .font(Theme.titleFont)
                        .foregroundColor(Theme.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEntry = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(Theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddDiaryEntrySheet(
                    selectedImage: $selectedImage,
                    selectedMood: $selectedMood,
                    notes: $notes,
                    onSave: {
                        viewModel.addEntry(
                            image: selectedImage ?? UIImage(),
                            mood: selectedMood,
                            notes: notes,
                            items: []
                        )
                        selectedImage = nil
                        selectedMood = "Happy"
                        notes = ""
                    }
                )
            }
            .onAppear {
                viewModel.fetchEntries()
            }
        }
    }
}

// MARK: - Supporting Views
struct MoodChip: View {
    let mood: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(mood)
                    .font(Theme.bodyFont)
                    .foregroundColor(isSelected ? .white : Theme.text)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
            }
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

struct DiaryEntryCard: View {
    let entry: OutfitEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(entry.date_ ?? Date(), style: .date)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.text)
                
                Spacer()
                
                Text(entry.mood_ ?? "")
                    .font(Theme.captionFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: Theme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
            }
            
            if let imageData = entry.imageData_, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if let notes = entry.notes_, !notes.isEmpty {
                Text(notes)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.text.opacity(0.7))
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

struct AddDiaryEntrySheet: View {
    @Binding var selectedImage: UIImage?
    @Binding var selectedMood: String
    @Binding var notes: String
    let onSave: () -> Void
    
    @State private var showingImagePicker = false
    @Environment(\.dismiss) private var dismiss
    
    let moods = ["Happy", "Confident", "Casual", "Professional", "Cozy", "Glamorous"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Photo").foregroundColor(Theme.primary)) {
                    Button(action: { showingImagePicker = true }) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(12)
                        } else {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Add Photo")
                            }
                            .foregroundColor(Theme.primary)
                        }
                    }
                }
                
                Section(header: Text("Mood").foregroundColor(Theme.primary)) {
                    Picker("Select Mood", selection: $selectedMood) {
                        ForEach(moods, id: \.self) { mood in
                            Text(mood).tag(mood)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Notes").foregroundColor(Theme.primary)) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .foregroundColor(Theme.primary)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotoLibraryPicker(image: $selectedImage)
            }
        }
    }
}

