import SwiftUI

struct ModelExplorerView: View {
    @State private var models: [AIModel] = [
        AIModel(name: "Llama 3 8B", description: "Meta's latest powerful LLM.", size: "4.7 GB", type: "General"),
        AIModel(name: "Phi-3 Mini", description: "Microsoft's lightweight and fast model.", size: "2.3 GB", type: "Lightweight"),
        AIModel(name: "Gemma 7B", description: "Google's versatile open model.", size: "4.2 GB", type: "Coding"),
        AIModel(name: "Moondream 2", description: "Small and efficient vision model.", size: "1.6 GB", type: "Vision")
    ]
    
    @State private var remoteModels: [AIModel] = [
        AIModel(name: "DeepSeek-V3", description: "Remote model via API.", size: "N/A", type: "API"),
        AIModel(name: "GPT-4o", description: "OpenAI's flagship model.", size: "N/A", type: "API"),
        AIModel(name: "Gemini 1.5 Pro", description: "Google's multimodal model.", size: "N/A", type: "API")
    ]
    
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var config = ConfigManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Model Explorer")
                    .font(theme.appFont(size: 32, weight: .bold))
                    .foregroundColor(theme.onSurface)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Local Models")
                        .font(theme.appFont(size: 20, weight: .semibold))
                        .foregroundColor(theme.onSurface)
                    
                    ForEach($models) { $model in
                        ModelCard(model: $model)
                    }
                }
                
                if config.isOllamaEnabled {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ollama Local Hub")
                            .font(theme.appFont(size: 20, weight: .semibold))
                            .foregroundColor(theme.onSurface)
                        
                        Text("Connected to \(config.ollamaEndpoint)")
                            .font(theme.appFont(size: 12))
                            .foregroundColor(theme.primary)
                        
                        // Mock Ollama models
                        ModelCard(model: .constant(AIModel(name: "Mistral 7B", description: "Running on local Ollama.", size: "4.1 GB", type: "Ollama", isDownloaded: true)))
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Remote & API Models")
                        .font(theme.appFont(size: 20, weight: .semibold))
                        .foregroundColor(theme.onSurface)
                    
                    ForEach($remoteModels) { $model in
                        ModelCard(model: $model)
                    }
                }
                
                if !config.huggingFaceToken.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Hugging Face Hub")
                            .font(theme.appFont(size: 20, weight: .semibold))
                            .foregroundColor(theme.onSurface)
                        
                        Text("Search and download from HF community.")
                            .font(theme.appFont(size: 14))
                            .foregroundColor(theme.onSurface.opacity(0.6))
                        
                        LuminaButton(label: "Browse Hugging Face", action: {
                            // Browse HF action
                        }, isPrimary: false)
                    }
                }
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
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
