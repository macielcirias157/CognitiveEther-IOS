import SwiftUI

struct PromptGalleryView: View {
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Prompt Gallery")
                    .font(theme.appFont(size: 32, weight: .bold))
                    .foregroundColor(theme.onSurface)
                
                VStack(alignment: .leading, spacing: 16) {
                    PromptCard(title: "Ethereal Narrator", description: "A creative storytelling mode with poetic output.", icon: "sparkles")
                    PromptCard(title: "Refactoring Sage", description: "Deep code analysis and refactoring suggestions.", icon: "cpu")
                    PromptCard(title: "Data Alchemist", description: "Extracting insights from complex raw data.", icon: "testtube.2")
                }
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
    }
}

struct PromptCard: View {
    let title: String
    let description: String
    let icon: String
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(theme.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.appFont(size: 18, weight: .semibold))
                    .foregroundColor(theme.onSurface)
                
                Text(description)
                    .font(theme.appFont(size: 14))
                    .foregroundColor(theme.onSurface.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(24)
        .background(theme.surfaceContainer)
        .cornerRadius(32)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(theme.outlineVariant.opacity(0.15), lineWidth: 1)
        )
    }
}
