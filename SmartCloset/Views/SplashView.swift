import SwiftUI

struct SplashView: View {
    @State private var isLogoVisible = false
    @State private var isSloganVisible = false
    @State private var sparkleOffset: CGFloat = -50
    @State private var sparkleOpacity = 0.0
    @State private var showMainView = false
    
    var body: some View {
        Group {
            if showMainView {
                MainTabView()
            } else {
                ZStack {
                    Theme.background
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        // Logo
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: Theme.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                // Sparkle effects
                                ForEach(0..<3) { i in
                                    Image(systemName: "sparkle")
                                        .font(.system(size: 20))
                                        .foregroundColor(Theme.primary)
                                        .offset(x: sparkleOffset + CGFloat(i * 20),
                                                y: sparkleOffset - CGFloat(i * 15))
                                        .opacity(sparkleOpacity)
                                }
                            }
                            .scaleEffect(isLogoVisible ? 1 : 0.5)
                            .opacity(isLogoVisible ? 1 : 0)
                        
                        // Slogan
                        Text("SmartCloset")
                            .font(Theme.titleFont)
                            .foregroundColor(Theme.primary)
                            .opacity(isSloganVisible ? 1 : 0)
                            .offset(y: isSloganVisible ? 0 : 20)
                        
                        Text("Your Virtual Wardrobe Assistant")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.text)
                            .opacity(isSloganVisible ? 0.8 : 0)
                            .offset(y: isSloganVisible ? 0 : 20)
                    }
                }
                .onAppear {
                    animateSplash()
                }
            }
        }
    }
    
    private func animateSplash() {
        // Logo animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            isLogoVisible = true
        }
        
        // Sparkle animation
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            sparkleOffset = 50
            sparkleOpacity = 1
        }
        
        // Slogan animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                isSloganVisible = true
            }
        }
        
        // Transition to main view
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showMainView = true
            }
        }
    }
} 