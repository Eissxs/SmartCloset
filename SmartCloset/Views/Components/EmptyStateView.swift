import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var action: (() -> Void)?
    var actionTitle: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 70))
                .foregroundColor(Theme.primary)
            
            Text(title)
                .font(Theme.titleFont)
                .foregroundColor(Theme.text)
            
            Text(message)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.text.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.bodyFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: Theme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
    }
} 