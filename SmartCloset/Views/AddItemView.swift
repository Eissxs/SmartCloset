import SwiftUI
import PhotosUI
import UIKit

struct AddItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ClosetViewModel
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingImageSource = false
    @State private var selectedCategory = "Tops"
    @State private var selectedColor = "Black"
    
    // Animation states
    @State private var isImageAnimating = false
    @State private var imageScale: CGFloat = 0.8
    @State private var imageOffset: CGFloat = 1000
    @State private var showFlash = false
    
    init(viewModel: ClosetViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Image Section
                Section {
                    VStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .scaleEffect(isImageAnimating ? 1 : imageScale)
                                .offset(x: 0, y: isImageAnimating ? 0 : imageOffset)
                        } else {
                            Button(action: { showingImageSource = true }) {
                                VStack {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Theme.primary)
                                        .padding(.bottom, 8)
                                    
                                    Text("Add Photo")
                                        .font(Theme.bodyFont)
                                        .foregroundColor(Theme.primary)
                                }
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .background(Theme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .opacity(showFlash ? 0.5 : 0)
                            .animation(.easeInOut(duration: 0.2), value: showFlash)
                    )
                } header: {
                    Text("Item Photo")
                }
                
                // Category Section
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(viewModel.categories.filter { $0 != "All" }, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                } header: {
                    Text("Category")
                }
                
                // Color Section
                Section {
                    Picker("Color", selection: $selectedColor) {
                        ForEach(viewModel.colors.filter { $0 != "All" }, id: \.self) { color in
                            Text(color).tag(color)
                        }
                    }
                } header: {
                    Text("Color")
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let image = selectedImage {
                            viewModel.addItem(image: image, category: selectedCategory, color: selectedColor)
                            dismiss()
                        }
                    }
                    .disabled(selectedImage == nil)
                }
            }
            .confirmationDialog("Choose Image Source", isPresented: $showingImageSource) {
                Button("Camera") {
                    showingCamera = true
                }
                Button("Photo Library") {
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotoLibraryPicker(image: $selectedImage)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(image: $selectedImage)
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isImageAnimating = true
                    showFlash = true
                }
                
                // Reset flash effect
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showFlash = false
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isImageAnimating = true
                }
            }
        }
    }
} 