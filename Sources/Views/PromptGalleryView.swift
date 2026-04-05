import SwiftUI

struct PromptGalleryView: View {
    @ObservedObject private var config = ConfigManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var searchText = ""
    @State private var selectedCategory = "All"

    private var categories: [String] {
        ["All"] + Array(Set(PromptPreset.catalog.map(\.category))).sorted()
    }

    private var filteredPresets: [PromptPreset] {
        PromptPreset.catalog.filter { preset in
            let matchesCategory = selectedCategory == "All" || preset.category == selectedCategory
            let matchesSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || preset.title.localizedCaseInsensitiveContains(searchText)
                || preset.description.localizedCaseInsensitiveContains(searchText)
                || preset.category.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Prompt Gallery")
                    .font(theme.appFont(size: 32, weight: .bold))
                    .foregroundColor(theme.onSurface)

                currentPromptCard
                searchBar
                categoryStrip

                VStack(alignment: .leading, spacing: 16) {
                    Text("Preset Library")
                        .font(theme.appFont(size: 20, weight: .semibold))
                        .foregroundColor(theme.onSurface)

                    ForEach(filteredPresets) { preset in
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

    private var currentPromptCard: some View {
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

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.onSurface.opacity(0.45))

            TextField("Search presets...", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundColor(theme.onSurface)
        }
        .padding(14)
        .background(theme.surfaceContainer)
        .cornerRadius(20)
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    Button(action: { selectedCategory = category }) {
                        Text(category)
                            .font(theme.appFont(size: 13, weight: .semibold))
                            .foregroundColor(selectedCategory == category ? .black : theme.onSurface)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(selectedCategory == category ? theme.primary : theme.surfaceContainer)
                            .cornerRadius(18)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
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

                    Text("\(preset.category) - \(preset.description)")
                        .font(theme.appFont(size: 14))
                        .foregroundColor(theme.onSurface.opacity(0.62))
                }
            }

            Text(preset.prompt)
                .font(theme.appFont(size: 13))
                .foregroundColor(theme.onSurface.opacity(0.58))
                .lineLimit(3)

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
