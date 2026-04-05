import SwiftUI

struct LabView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var config = ConfigManager.shared

    private let presets: [PromptPreset] = [
        PromptPreset(
            title: "Pragmatic Engineer",
            description: "Direct, implementation-focused answers with explicit tradeoffs and next steps.",
            icon: "hammer",
            prompt: "You are a pragmatic senior engineer. Answer directly, reason clearly, and optimize for execution."
        ),
        PromptPreset(
            title: "Research Analyst",
            description: "Structured synthesis, assumptions called out, and concise conclusions.",
            icon: "chart.bar.doc.horizontal",
            prompt: "You are a research analyst. Summarize facts, note uncertainty, and separate findings from interpretation."
        ),
        PromptPreset(
            title: "Writing Editor",
            description: "Tightens drafts, improves structure, and preserves the original intent.",
            icon: "text.quote",
            prompt: "You are an editor. Rewrite for clarity, precision, and flow while preserving the author's meaning."
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Prompt Lab")
                    .font(theme.appFont(size: 32, weight: .bold))
                    .foregroundColor(theme.onSurface)

                activePromptCard

                VStack(alignment: .leading, spacing: 16) {
                    Text("Reusable Presets")
                        .font(theme.appFont(size: 20, weight: .semibold))
                        .foregroundColor(theme.onSurface)

                    ForEach(presets) { preset in
                        PromptPresetCard(preset: preset) {
                            config.defaultSystemPrompt = preset.prompt
                        }
                    }
                }
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
    }

    private var activePromptCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Current System Prompt")
                .font(theme.appFont(size: 18, weight: .semibold))
                .foregroundColor(theme.onSurface)

            Text(config.defaultSystemPrompt)
                .font(theme.appFont(size: 14))
                .foregroundColor(theme.onSurface.opacity(0.7))

            Text("Applying a preset replaces the default runtime behavior immediately for future requests.")
                .font(theme.appFont(size: 12))
                .foregroundColor(theme.onSurface.opacity(0.5))
        }
        .padding(22)
        .background(theme.surfaceContainer)
        .cornerRadius(28)
    }
}

private struct PromptPreset: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let prompt: String
}

private struct PromptPresetCard: View {
    let preset: PromptPreset
    let onApply: () -> Void

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: preset.icon)
                    .font(.system(size: 20))
                    .foregroundColor(theme.primary)
                    .frame(width: 52, height: 52)
                    .background(theme.surfaceContainerHigh)
                    .cornerRadius(16)

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.title)
                        .font(theme.appFont(size: 18, weight: .semibold))
                        .foregroundColor(theme.onSurface)

                    Text(preset.description)
                        .font(theme.appFont(size: 14))
                        .foregroundColor(theme.onSurface.opacity(0.62))
                }
            }

            LuminaButton(label: "Apply Preset", action: onApply, isPrimary: true)
        }
        .padding(22)
        .background(theme.surfaceContainer)
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(theme.outlineVariant.opacity(0.15), lineWidth: 1)
        )
    }
}
