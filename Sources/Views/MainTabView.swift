import SwiftUI

struct MainTabView: View {
    @ObservedObject var theme = ThemeManager.shared
    
    init() {
        // Customize TabBar appearance
        UITabBar.appearance().backgroundColor = UIColor(theme.surface.opacity(0.8))
        UITabBar.appearance().unselectedItemTintColor = UIColor(theme.onSurface.opacity(0.4))
    }
    
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }
            
            ModelExplorerView()
                .tabItem {
                    Label("Models", systemImage: "square.grid.2x2")
                }
            
            ResourceMonitorView()
                .tabItem {
                    Label("Monitor", systemImage: "gauge")
                }
            
            MCPMarketplaceView()
                .tabItem {
                    Label("Skills", systemImage: "puzzlepiece")
                }
            
            LabView()
                .tabItem {
                    Label("Lab", systemImage: "flask")
                }
        }
        .accentColor(theme.primary)
    }
}
