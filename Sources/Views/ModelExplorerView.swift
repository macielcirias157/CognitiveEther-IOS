import SwiftUI

struct ModelExplorerView: View {
    @ObservedObject var aiManager = AIManager.shared
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var config = ConfigManager.shared
    
    @State private var remoteModels: [AIModel] = [
        AIModel(name: "DeepSeek-V3", description: "Remote model via API.", size: "N/A", type: "API"),
        AIModel(name: "GPT-4o", description: "OpenAI's flagship model.", size: "N/A", type: "API"),
        AIModel(name: "Gemini 1.5 Pro", description: "Google's multimodal model.", size: "N/A", type: "API")
    ]
    
    @State private var isPulling = false
    @State private var pullError: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Model Explorer")
                    .font(theme.appFont(size: 32, weight: .bold))
                    .foregroundColor(theme.onSurface)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Ollama Local Models")
                        .font(theme.appFont(size: 20, weight: .semibold))
                        .foregroundColor(theme.onSurface)
                    
                    if config.isOllamaEnabled {
                        if aiManager.localModels.isEmpty {
                            Text("No local models found. Make sure Ollama is running.")
                                .font(theme.appFont(size: 14))
                                .foregroundColor(theme.onSurface.opacity(0.6))
                        } else {
                            ForEach(aiManager.localModels) { ollamaModel in
                                LocalModelCard(model: ollamaModel)
                            }
                        }
                    } else {
                        Text("Enable Ollama in Settings to see local models.")
                            .font(theme.appFont(size: 14))
                            .foregroundColor(theme.onSurface.opacity(0.6))
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recommended for Download")
                        .font(theme.appFont(size: 20, weight: .semibold))
                        .foregroundColor(theme.onSurface)
                    
                    DownloadCard(name: "llama3", description: "Meta's latest 8B model.", size: "4.7 GB")
                    DownloadCard(name: "phi3", description: "Microsoft's efficient mini model.", size: "2.3 GB")
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Remote & API Models")
                        .font(theme.appFont(size: 20, weight: .semibold))
                        .foregroundColor(theme.onSurface)
                    
                    ForEach($remoteModels) { $model in
                        ModelCard(model: $model)
                    }
                }
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
        .onAppear {
            Task {
                await aiManager.listLocalModels()
            }
        }
    }
}

struct LocalModelCard: View {
    let model: OllamaModel
    @ObservedObject var aiManager = AIManager.shared
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(theme.appFont(size: 18, weight: .semibold))
                        .foregroundColor(theme.onSurface)
                    Text("\(model.details.parameter_size) • \(formatSize(model.size))")
                        .font(theme.appFont(size: 12))
                        .foregroundColor(theme.primary)
                }
                Spacer()
                Button(action: {
                    Task {
                        try? await aiManager.deleteModel(name: model.name)
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.7))
                }
            }
        }
        .padding()
        .background(theme.surfaceContainer)
        .cornerRadius(20)
    }
    
    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct DownloadCard: View {
    let name: String
    let description: String
    let size: String
    @ObservedObject var aiManager = AIManager.shared
    @ObservedObject var theme = ThemeManager.shared
    @State private var isDownloading = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(theme.appFont(size: 18, weight: .semibold))
                    .foregroundColor(theme.onSurface)
                Text("\(description) • \(size)")
                    .font(theme.appFont(size: 14))
                    .foregroundColor(theme.onSurface.opacity(0.6))
            }
            Spacer()
            if isDownloading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
            } else {
                Button(action: {
                    isDownloading = true
                    Task {
                        do {
                            try await aiManager.pullModel(name: name)
                        } catch {
                            print("Failed to pull: \(error)")
                        }
                        isDownloading = false
                    }
                }) {
                    Image(systemName: "icloud.and.arrow.down")
                        .foregroundColor(theme.primary)
                }
            }
        }
        .padding()
        .background(theme.surfaceContainer)
        .cornerRadius(20)
    }
}

struct ModelCard: View {
    @Binding var model: AIModel
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(theme.appFont(size: 18, weight: .semibold))
                        .foregroundColor(theme.onSurface)
                    
                    Text(model.type)
                        .font(theme.appFont(size: 12, weight: .medium))
                        .foregroundColor(theme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.primary.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                if model.isDownloaded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.primary)
                } else if model.downloadProgress > 0 {
                    ProgressView(value: model.downloadProgress)
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                } else {
                    Button(action: {
                        // Start download simulation
                        startDownload()
                    }) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 24))
                            .foregroundColor(theme.onSurface.opacity(0.6))
                    }
                }
            }
            
            Text(model.description)
                .font(theme.appFont(size: 14))
                .foregroundColor(theme.onSurface.opacity(0.7))
            
            HStack {
                Text(model.size)
                    .font(theme.appFont(size: 12))
                    .foregroundColor(theme.onSurface.opacity(0.5))
                Spacer()
            }
        }
        .padding(20)
        .background(theme.surfaceContainer)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.outlineVariant.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func startDownload() {
        // Mock download progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if model.downloadProgress < 1.0 {
                model.downloadProgress += 0.05
            } else {
                model.isDownloaded = true
                model.downloadProgress = 0
                timer.invalidate()
            }
        }
    }
}
