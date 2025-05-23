import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    VStack {
                        Image(systemName: "house.fill")
                            .environment(\.symbolVariants, .none)
                        Text("Home")
                    }
                }
                .tag(0)
            
            ClosetView(viewModel: ClosetViewModel(context: viewContext))
                .tabItem {
                    VStack {
                        Image(systemName: "tshirt.fill")
                            .environment(\.symbolVariants, .none)
                        Text("Closet")
                    }
                }
                .tag(1)
            
            OutfitPlannerView(viewContext: viewContext)
                .tabItem {
                    VStack {
                        Image(systemName: "calendar")
                            .environment(\.symbolVariants, .none)
                        Text("Planner")
                    }
                }
                .tag(2)
            
            StyleDiaryView()
                .tabItem {
                    VStack {
                        Image(systemName: "book.fill")
                            .environment(\.symbolVariants, .none)
                        Text("Diary")
                    }
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    VStack {
                        Image(systemName: "gear")
                            .environment(\.symbolVariants, .none)
                        Text("Settings")
                    }
                }
                .tag(4)
        }
        .accentColor(Theme.primary)
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            // Adjust tab bar item spacing and positioning
            appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)
            appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -1)
            
            // Set the tab bar height
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let tabBarController = windowScene.windows.first?.rootViewController as? UITabBarController {
                tabBarController.tabBar.itemPositioning = .centered
                tabBarController.tabBar.itemSpacing = 50 // Adjust this value as needed
            }
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
} 