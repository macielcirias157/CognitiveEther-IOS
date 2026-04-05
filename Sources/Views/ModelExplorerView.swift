import SwiftUI

struct ModelExplorerView: View {
    @ObservedObject private var aiManager = AIManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var config = ConfigManager.shared

    @State private var operationError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Model Explorer")
                    .font(theme.appFont(size: 32, weight: .bold))
                    .foregroundColor(theme.onSurface)

                defaultRoutingCard
                localModelsSection
                downloadsSection
                cloudProvidersSection
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
        .task {
            await aiManager.listLocalModels()
        }
        .alert("Model operation failed", isPresented: Binding(
            get: { operationError != nil },
            set: { if !$0 { operationError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(operationError ?? "")
        }
    }

    private var defaultRoutingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Current Routing")
                .font(theme.appFont(size: 18, weight: .semibold))
                .foregroundColor(theme.onSurface)

            Text("Preferred provider: \(config.selectedProvider.displayName)")
                .font(theme.appFont(size: 15))
                .foregroundColor(theme.onSurface.opacity(0.75))

            Text("Active model: \(config.modelName(for: config.selectedProvider))")
                .font(theme.appFont(size: 14))
                .foregroundColor(theme.primary)

            Text("The chat screen will fall back automatically if the preferred provider is not configured.")
                .font(theme.appFont(size: 13))
                .foregroundColor(theme.onSurface.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(theme.surfaceContainer)
        .cornerRadius(28)
    }

    private var localModelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ollama Local Models")
                .font(theme.appFont(size: 20, weight: .semibold))
                .foregroundColor(theme.onSurface)

            if !config.isOllamaEnabled {
                ModelExplorerInfoCard(text: "Enable Ollama in Settings to inspect or select local models.")
            } else if aiManager.localModels.isEmpty {
                ModelExplorerInfoCard(text: "No local models found yet. Refresh after starting Ollama or pull one below.")
            } else {
                ForEach(aiManager.localModels) { model in
                    LocalModelCard(
                        model: model,
                        isSelected: config.ollamaModelName == model.name,
                        onSelect: { config.ollamaModelName = model.name },
                        onDelete: {
                            Task {
                                do {
                                    try await aiManager.deleteModel(name: model.name)
                                } catch {
                                    await MainActor.run {
                                        operationError = error.localizedDescription
                                    }
                                }
                            }
                        }
                    )
                }
            }
        }
    }

    private var downloadsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommended Downloads")
                .font(theme.appFont(size: 20, weight: .semibold))
                .foregroundColor(theme.onSurface)

            DownloadCard(name: "llama3", description: "Balanced general-purpose local model.", size: "4.7 GB") {
                try await aiManager.pullModel(name: "llama3")
            } onFailure: { error in
                operationError = error.localizedDescription
            }

            DownloadCard(name: "phi3", description: "Smaller local model for quick tasks.", size: "2.3 GB") {
                try await aiManager.pullModel(name: "phi3")
            } onFailure: { error in
                operationError = error.localizedDescription
            }
        }
    }

    private var cloudProvidersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cloud Providers")
                .font(theme.appFont(size: 20, weight: .semibold))
                .foregroundColor(theme.onSurface)

            ForEach(AIProvider.allCases.filter { $0 != .ollama }, id: \.self) { provider in
                CloudProviderCard(
                    provider: provider,
                    isConfigured: config.isConfigured(for: provider),
                    currentModel: config.modelName(for: provider),
                    isPreferred: config.selectedProvider == provider,
                    onUseAsDefault: { config.selectedProvider = provider }
                )
            }
        }
    }
}

private struct LocalModelCard: View {
    let model: OllamaModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(model.name)
                        .font(theme.appFont(size: 18, weight: .semibold))
                        .foregroundColor(theme.onSurface)

                    Text("\(model.details.parameter_size) - \(formatSize(model.size))")
                        .font(theme.appFont(size: 12))
                        .foregroundColor(theme.primary)

                    Text(model.details.family)
                        .font(theme.appFont(size: 12))
                        .foregroundColor(theme.onSurface.opacity(0.5))
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 34, height: 34)
                        .background(theme.surfaceContainerLow)
                        .clipShape(Circle())
                }
            }

            LuminaButton(label: isSelected ? "Selected for Chat" : "Use in Chat", action: onSelect, isPrimary: isSelected)
        }
        .padding(20)
        .background(theme.surfaceContainer)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isSelected ? theme.primary.opacity(0.35) : theme.outlineVariant.opacity(0.15), lineWidth: 1)
        )
    }

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

private struct DownloadCard: View {
    let name: String
    let description: String
    let size: String
    let action: () async throws -> Void
    let onFailure: (Error) -> Void

    @ObservedObject private var theme = ThemeManager.shared
    @State private var isDownloading = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(theme.appFont(size: 18, weight: .semibold))
                    .foregroundColor(theme.onSurface)

                Text("\(description) - \(size)")
                    .font(theme.appFont(size: 14))
                    .foregroundColor(theme.onSurface.opacity(0.6))
            }

            Spacer()

            if isDownloading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
            } else {
                Button(action: download) {
                    Image(systemName: "icloud.and.arrow.down")
                        .foregroundColor(theme.primary)
                        .frame(width: 42, height: 42)
                        .background(theme.surfaceContainerLow)
                        .clipShape(Circle())
                }
            }
        }
        .padding(20)
        .background(theme.surfaceContainer)
        .cornerRadius(24)
    }

    private func download() {
        isDownloading = true
        Task {
            do {
                try await action()
            } catch {
                await MainActor.run {
                    onFailure(error)
                }
            }
            await MainActor.run {
                isDownloading = false
            }
        }
    }
}

private struct CloudProviderCard: View {
    let provider: AIProvider
    let isConfigured: Bool
    let currentModel: String
    let isPreferred: Bool
    let onUseAsDefault: () -> Void

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(provider.displayName)
                        .font(theme.appFont(size: 18, weight: .semibold))
                        .foregroundColor(theme.onSurface)

                    Text(currentModel)
                        .font(theme.appFont(size: 13))
                        .foregroundColor(theme.primary)
                }

                Spacer()

                Text(isConfigured ? "Configured" : "Missing key")
                    .font(theme.appFont(size: 12, weight: .semibold))
                    .foregroundColor(isConfigured ? .green : .orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background((isConfigured ? Color.green : Color.orange).opacity(0.14))
                    .cornerRadius(12)
            }

            Text(isPreferred ? "This provider is currently preferred for new requests." : "Use this provider as the default routing target.")
                .font(theme.appFont(size: 13))
                .foregroundColor(theme.onSurface.opacity(0.58))

            LuminaButton(
                label: isPreferred ? "Preferred Provider" : "Use As Default",
                action: onUseAsDefault,
                isPrimary: isPreferred
            )
        }
        .padding(20)
        .background(theme.surfaceContainer)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isPreferred ? theme.primary.opacity(0.35) : theme.outlineVariant.opacity(0.15), lineWidth: 1)
        )
    }
}

private struct ModelExplorerInfoCard: View {
    let text: String

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        Text(text)
            .font(theme.appFont(size: 14))
            .foregroundColor(theme.onSurface.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(theme.surfaceContainer)
            .cornerRadius(24)
    }
}
