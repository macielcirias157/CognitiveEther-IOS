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
            await aiManager.refreshAllCatalogs()
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

            ForEach([AIProvider.openAI, .deepSeek, .gemini], id: \.self) { provider in
                CapabilityStatusRow(
                    title: provider.displayName,
                    subtitle: aiManager.status(for: provider).message,
                    status: providerStatusLabel(provider),
                    tint: providerStatusColor(provider)
                )
            }

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
                description: "Controls the browsing capability flag used by the assistant runtime.",
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
            Text("Operational Features")
                .font(theme.appFont(size: 20, weight: .semibold))
                .foregroundColor(theme.onSurface)

            CapabilityStatusRow(
                title: "History Export",
                subtitle: "Conversation history can be exported from the History screen as a JSON archive.",
                status: "Ready",
                tint: .green
            )

            CapabilityStatusRow(
                title: "Semantic Memory",
                subtitle: "Recent conversations can be injected into new requests when memory is enabled.",
                status: config.isSemanticMemoryEnabled ? "Enabled" : "Disabled",
                tint: config.isSemanticMemoryEnabled ? .green : .orange
            )

            CapabilityStatusRow(
                title: "Siri Shortcuts",
                subtitle: "The app exposes an App Intent so prompts can be sent through Shortcuts.",
                status: "Ready",
                tint: .green
            )
        }
    }

    private func providerStatusLabel(_ provider: AIProvider) -> String {
        switch aiManager.status(for: provider).phase {
        case .connected:
            return "Connected"
        case .checking:
            return "Checking"
        case .failed:
            return "Failed"
        case .notConfigured:
            return "Not configured"
        case .idle:
            return config.isConfigured(for: provider) ? "Idle" : "Not configured"
        }
    }

    private func providerStatusColor(_ provider: AIProvider) -> Color {
        switch aiManager.status(for: provider).phase {
        case .connected:
            return .green
        case .checking:
            return theme.primary
        case .failed:
            return .red
        case .notConfigured:
            return .orange
        case .idle:
            return config.isConfigured(for: provider) ? theme.onSurface.opacity(0.55) : .orange
        }
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
