import SwiftUI

struct PromptGalleryView: View {
    @ObservedObject private var config = ConfigManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var isShowingNewPromptSheet = false
    @State private var newPromptTitle = ""
    @State private var newPromptContent = ""

    private var categories: [String] {
        let presetCategories = Set(PromptPreset.catalog.map(\.category))
        let allCategories = presetCategories.union(["Custom"])
        return ["All"] + Array(allCategories).sorted()
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
                Text(Localization.promptGallery)
                    .font(theme.appFont(size: 32, weight: .bold))
                    .foregroundColor(theme.onSurface)

                currentPromptCard
                searchBar
                categoryStrip
                
                customPromptsSection
                presetSection
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
        .sheet(isPresented: $isShowingNewPromptSheet) {
            NavigationStack {
                Form {
                    Section(header: Text(Localization.createPrompt)) {
                        TextField(Localization.promptTitle, text: $newPromptTitle)
                        TextEditor(text: $newPromptContent)
                            .frame(minHeight: 150)
                    }
                }
                .navigationTitle(Localization.createPrompt)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(Localization.cancel) {
                            newPromptTitle = ""
                            newPromptContent = ""
                            isShowingNewPromptSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(Localization.save) {
                            if !newPromptTitle.isEmpty && !newPromptContent.isEmpty {
                                config.addCustomPrompt(title: newPromptTitle, content: newPromptContent)
                                newPromptTitle = ""
                                newPromptContent = ""
                            }
                            isShowingNewPromptSheet = false
                        }
                        .disabled(newPromptTitle.isEmpty || newPromptContent.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var currentPromptCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(Localization.currentPrompt)
                .font(theme.appFont(size: 18, weight: .semibold))
                .foregroundColor(theme.onSurface)

            if let activePrompt = config.activeCustomPrompt() {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(theme.primary)
                    Text("\(activePrompt.title) (Active)")
                        .font(theme.appFont(size: 12, weight: .semibold))
                        .foregroundColor(theme.primary)
                }
            }
            
            Text(config.effectiveSystemPrompt())
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

            TextField(Localization.searchPresets, text: $searchText)
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
    
    private var customPromptsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(Localization.customPrompts)
                    .font(theme.appFont(size: 20, weight: .semibold))
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Button(action: { isShowingNewPromptSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.primary)
                }
            }
            
            if config.customPrompts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No custom prompts yet.")
                        .font(theme.appFont(size: 14))
                        .foregroundColor(theme.onSurface.opacity(0.6))
                    
                    Text("Create your own prompts to customize the AI behavior.")
                        .font(theme.appFont(size: 12))
                        .foregroundColor(theme.onSurface.opacity(0.45))
                }
                .padding(18)
                .background(theme.surfaceContainer)
                .cornerRadius(24)
            } else {
                ForEach(config.customPrompts) { prompt in
                    CustomPromptCard(
                        prompt: prompt,
                        isActive: config.activeCustomPromptID == prompt.id,
                        onApply: { config.useCustomPrompt(id: prompt.id) },
                        onDelete: { config.removeCustomPrompt(id: prompt.id) }
                    )
                }
            }
        }
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Localization.presetLibrary)
                .font(theme.appFont(size: 20, weight: .semibold))
                .foregroundColor(theme.onSurface)

            ForEach(filteredPresets) { preset in
                PromptPresetCard(preset: preset) {
                    config.defaultSystemPrompt = preset.prompt
                    config.activeCustomPromptID = nil
                }
            }
        }
    }
}

private struct CustomPromptCard: View {
    let prompt: CustomPrompt
    let isActive: Bool
    let onApply: () -> Void
    let onDelete: () -> Void

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.primary)
                    .frame(width: 52, height: 52)
                    .background(theme.surfaceContainerHigh)
                    .cornerRadius(16)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(prompt.title)
                            .font(theme.appFont(size: 18, weight: .semibold))
                            .foregroundColor(theme.onSurface)
                        
                        Spacer()
                        
                        if isActive {
                            Text(Localization.active)
                                .font(theme.appFont(size: 10, weight: .semibold))
                                .foregroundColor(theme.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(theme.primary.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }

                    Text(prompt.content.prefix(100) + (prompt.content.count > 100 ? "..." : ""))
                        .font(theme.appFont(size: 14))
                        .foregroundColor(theme.onSurface.opacity(0.62))
                }
            }

            Text(prompt.content)
                .font(theme.appFont(size: 13))
                .foregroundColor(theme.onSurface.opacity(0.58))
                .lineLimit(3)

            HStack(spacing: 12) {
                LuminaButton(label: Localization.applyPreset, action: onApply, isPrimary: !isActive)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .background(theme.surfaceContainerLow)
                        .cornerRadius(12)
                }
            }
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

            LuminaButton(label: Localization.applyPreset, action: onApply, isPrimary: true)
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