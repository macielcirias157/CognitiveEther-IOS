import SwiftUI

struct LabView: View {
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Multi-modal Lab")
                    .font(theme.appFont(size: 32, weight: .bold))
                    .foregroundColor(theme.onSurface)
                
                VStack(alignment: .leading, spacing: 16) {
                    LabModule(title: "Document Analysis", description: "Upload and analyze PDFs, Word, and text files locally.", icon: "doc.text.magnifyingglass")
                    LabModule(title: "Audio Transcription", description: "Convert speech to text using Whisper-large-v3.", icon: "waveform.circle")
                    LabModule(title: "Visual Direct Capture", description: "Use the camera for real-time vision analysis.", icon: "camera.viewfinder")
                }
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
    }
}

struct LabModule: View {
    let title: String
    let description: String
    let icon: String
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(theme.primary)
                    .frame(width: 56, height: 56)
                    .background(theme.surfaceContainerHigh)
                    .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(theme.appFont(size: 18, weight: .semibold))
                        .foregroundColor(theme.onSurface)
                    
                    Text(description)
                        .font(theme.appFont(size: 14))
                        .foregroundColor(theme.onSurface.opacity(0.6))
                }
            }
            
            LuminaButton(label: "Launch Module", action: {
                // Launch module action
            }, isPrimary: true)
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
