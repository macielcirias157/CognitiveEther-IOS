import SwiftUI

struct MCPMarketplaceView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var config = ConfigManager.shared
    @ObservedObject private var aiManager = AIManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Capabilities")
                    .font(theme.appFont(size: 32, weight: .bold))
                    .foregroundColor(theme.onSurface)

                statusSection
                togglesSection
                integrationSection
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
        .task {
            await aiManager.listLocalModels()
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Runtime Status")
                .font(theme.appFont(size: 20, weight: .semibold))
                .foregroundColor(theme.onSurface)

            CapabilityStatusRow(
                title: "Ollama",
                subtitle: config.isOllamaEnabled
                    ? "Endpoint: \(config.ollamaEndpoint)"
                    : "Disabled in settings.",
                status: config.isOllamaEnabled ? "Enabled" : "Disabled",
                tint: config.isOllamaEnabled ? .green : .orange
            )

            CapabilityStatusRow(
                title: "Cloud Providers",
                subtitle: "\(configuredCloudProviders) configured",
                status: configuredCloudProviders > 0 ? "Ready" : "Missing keys",
                tint: configuredCloudProviders > 0 ? .green : .orange
            )

            CapabilityStatusRow(
                title: "Local Models",
                subtitle: "\(aiManager.localModels.count) Ollama models detected",
                status: aiManager.localModels.isEmpty ? "Empty" : "Available",
                tint: aiManager.localModels.isEmpty ? .orange : .green
            )
        }
    }

    private var togglesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Capabilities")
                .font(theme.appFont(size: 20, weight: .semibold))
                .foregroundColor(theme.onSurface)

            CapabilityToggleRow(
                name: "Cross-session Memory",
                description: "Injects relevant context from recent conversations into new prompts.",
                icon: "brain.head.profile",
                isEnabled: $config.isSemanticMemoryEnabled
            )

            CapabilityToggleRow(
                name: "Web Browsing",
                description: "Reserved switch for future browsing workflows. It does not invoke browsing by itself.",
                icon: "globe",
                isEnabled: $config.isWebBrowsingEnabled
            )

            CapabilityToggleRow(
                name: "Ollama Access",
                description: "Enables local model discovery and inference through your Ollama endpoint.",
                icon: "network",
                isEnabled: $config.isOllamaEnabled
            )
        }
    }

    private var integrationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("External Integrations")
                .font(theme.appFont(size: 20, weight: .semibold))
                .foregroundColor(theme.onSurface)

            CapabilityStatusRow(
                title: "GitHub MCP",
                subtitle: "Not wired into the iOS app yet. If you want repo actions inside the app, we can define the flow next.",
                status: "Pending",
                tint: .orange
            )

            CapabilityStatusRow(
                title: "Semantic Memory Store",
                subtitle: "Current implementation reuses persisted conversations. Vector search is not implemented yet.",
                status: config.isSemanticMemoryEnabled ? "Basic" : "Off",
                tint: config.isSemanticMemoryEnabled ? .yellow : .orange
            )
        }
    }

    private var configuredCloudProviders: Int {
        [AIProvider.openAI, .deepSeek, .gemini].filter { config.isConfigured(for: $0) }.count
    }
}

private struct CapabilityStatusRow: View {
    let title: String
    let subtitle: String
    let status: String
    let tint: Color

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(tint)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(theme.appFont(size: 16, weight: .semibold))
                        .foregroundColor(theme.onSurface)

                    Spacer()

                    Text(status)
                        .font(theme.appFont(size: 12, weight: .semibold))
                        .foregroundColor(tint)
                }

                Text(subtitle)
                    .font(theme.appFont(size: 13))
                    .foregroundColor(theme.onSurface.opacity(0.62))
            }
        }
        .padding(18)
        .background(theme.surfaceContainer)
        .cornerRadius(24)
    }
}

private struct CapabilityToggleRow: View {
    let name: String
    let description: String
    let icon: String
    @Binding var isEnabled: Bool

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(theme.primary)
                .frame(width: 48, height: 48)
                .background(theme.surfaceContainerHigh)
                .cornerRadius(14)

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
    }
}
