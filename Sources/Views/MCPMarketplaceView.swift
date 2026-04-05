import SwiftUI

struct Skill: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    var isEnabled: Bool = false
}

struct MCPMarketplaceView: View {
    @State private var skills: [Skill] = [
        Skill(name: "File Explorer", description: "Search and read local files.", icon: "folder.badge.search"),
        Skill(name: "Web Search", description: "Access live internet data.", icon: "globe"),
        Skill(name: "SQLite Integration", description: "Connect to local databases.", icon: "externaldrive.badge.icloud"),
        Skill(name: "GitHub Client", description: "Manage repositories and PRs.", icon: "terminal"),
        Skill(name: "Ollama Local API", description: "Bridge to your local Ollama server.", icon: "network")
    ]
    
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var config = ConfigManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Skills & MCP Marketplace")
                    .font(theme.appFont(size: 32, weight: .bold))
                    .foregroundColor(theme.onSurface)
                
                if config.isOllamaEnabled {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Ollama Connected: \(config.ollamaEndpoint)")
                            .font(theme.appFont(size: 14))
                            .foregroundColor(theme.onSurface.opacity(0.6))
                    }
                    .padding()
                    .background(theme.surfaceContainerLow)
                    .cornerRadius(16)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Local Skills")
                        .font(theme.appFont(size: 20, weight: .semibold))
                        .foregroundColor(theme.onSurface)
                    
                    SkillRow(name: "File Explorer", description: "Search and read local files.", icon: "folder.badge.search", isEnabled: .constant(true))
                    SkillRow(name: "Web Search", description: "Access live internet data.", icon: "globe", isEnabled: .constant(true))
                    SkillRow(name: "SQLite Integration", description: "Connect to local databases.", icon: "externaldrive.badge.icloud", isEnabled: .constant(false))
                    SkillRow(name: "GitHub Client", description: "Manage repositories and PRs.", icon: "terminal", isEnabled: .constant(false))
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Advanced AI Skills")
                        .font(theme.appFont(size: 20, weight: .semibold))
                        .foregroundColor(theme.onSurface)
                    
                    SkillRow(name: "Semantic Memory", description: "Retain context and facts across different chat sessions.", icon: "brain.headset", isEnabled: $config.isSemanticMemoryEnabled)
                    
                    SkillRow(name: "Web Browser (MCP)", description: "Open a headless browser to navigate and extract web content.", icon: "safari", isEnabled: $config.isWebBrowsingEnabled)
                    
                    SkillRow(name: "Ollama Local API", description: "Bridge to your local Ollama server.", icon: "network", isEnabled: $config.isOllamaEnabled)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Discover New Skills")
                        .font(theme.appFont(size: 20, weight: .semibold))
                        .foregroundColor(theme.onSurface)
                    
                    Text("Browse the community store for new MCP servers and integrations.")
                        .font(theme.appFont(size: 14))
                        .foregroundColor(theme.onSurface.opacity(0.6))
                    
                    LuminaButton(label: "Open Store", action: {
                        // Open store action
                    }, isPrimary: false)
                }
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
    }
}

struct SkillRow: View {
    let name: String
    let description: String
    let icon: String
    @Binding var isEnabled: Bool
    
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(theme.primary)
                .frame(width: 48, height: 48)
                .background(theme.surfaceContainerHigh)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(theme.appFont(size: 16, weight: .semibold))
                    .foregroundColor(theme.onSurface)
                
                Text(description)
                    .font(theme.appFont(size: 12))
                    .foregroundColor(theme.onSurface.opacity(0.6))
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: theme.primary))
        }
        .padding(16)
        .background(theme.surfaceContainer)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.outlineVariant.opacity(0.15), lineWidth: 1)
        )
    }
}
