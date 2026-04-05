import SwiftUI

@main
struct CognitiveEtherApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .environmentObject(themeManager)
        }
    }
}
