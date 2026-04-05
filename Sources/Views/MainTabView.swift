import SwiftUI

struct MainTabView: View {
    @ObservedObject var theme = ThemeManager.shared
    
    init() {
        UITabBar.appearance().backgroundColor = UIColor(theme.surface.opacity(0.8))
        UITabBar.appearance().unselectedItemTintColor = UIColor(theme.onSurface.opacity(0.4))
    }
    
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label(Localization.chat, systemImage: "bubble.left.and.bubble.right")
                }
            
            ModelExplorerView()
                .tabItem {
                    Label(Localization.models, systemImage: "square.grid.2x2")
                }
            
            ResourceMonitorView()
                .tabItem {
                    Label(Localization.monitor, systemImage: "gauge")
                }
            
            MCPMarketplaceView()
                .tabItem {
                    Label(Localization.tools, systemImage: "puzzlepiece")
                }
            
            LabView()
                .tabItem {
                    Label(Localization.prompts, systemImage: "flask")
                }
        }
        .accentColor(theme.primary)
        .onAppear {
            Task {
                await AIManager.shared.listLocalModels()
                await AIManager.shared.refreshAllCatalogs()
            }
        }
    }
}