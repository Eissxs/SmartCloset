import SwiftUI

struct OptimizedItemThumbnail: View {
    let item: ClosetItem
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ProgressView()
                    .frame(width: 80, height: 80)
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .task {
                        await loadImage()
                    }
            }
        }
    }
    
    private func loadImage() async {
        guard let imageData = item.imageData_ as Data? else { return }
        if let loadedImage = UIImage(data: imageData) {
            await MainActor.run {
                image = loadedImage
            }
        }
    }
} 