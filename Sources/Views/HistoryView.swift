import SwiftUI

struct HistoryView: View {
    let onConversationSelected: (() -> Void)?

    @ObservedObject private var store = ConversationStore.shared
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var config = ConfigManager.shared

    @State private var isShowingClearAlert = false

    init(onConversationSelected: (() -> Void)? = nil) {
        self.onConversationSelected = onConversationSelected
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                statsGrid
                sessionsSection
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
        .alert("Clear all conversations?", isPresented: $isShowingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                ConversationStore.shared.clearHistory()
            }
        } message: {
            Text("This removes every saved chat session from local storage.")
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Conversation History")
                    .font(theme.appFont(size: 30, weight: .bold))
                    .foregroundColor(theme.onSurface)

                Text("Your chats now persist locally and can be resumed at any time.")
                    .font(theme.appFont(size: 14))
                    .foregroundColor(theme.onSurface.opacity(0.65))
            }

            Spacer()

            VStack(spacing: 12) {
                SmallActionButton(label: "New", systemImage: "square.and.pencil") {
                    ConversationStore.shared.createNewSession()
                    onConversationSelected?()
                }

                SmallActionButton(label: "Clear", systemImage: "trash") {
                    isShowingClearAlert = true
                }
            }
        }
    }

    private var statsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                HistoryStatCard(
                    title: "Sessions",
                    value: "\(store.sessions.count)",
                    subtitle: "Saved conversations"
                )

                HistoryStatCard(
                    title: "Messages",
                    value: "\(store.totalMessageCount)",
                    subtitle: "Across all chats"
                )
            }

            HStack(spacing: 12) {
                HistoryStatCard(
                    title: "Memory",
                    value: config.isSemanticMemoryEnabled ? "On" : "Off",
                    subtitle: "Cross-session context"
                )

                HistoryStatCard(
                    title: "Primary",
                    value: primaryProviderLabel,
                    subtitle: "Most used provider"
                )
            }
        }
    }

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Saved Sessions")
                .font(theme.appFont(size: 20, weight: .semibold))
                .foregroundColor(theme.onSurface)

            if store.sessions.isEmpty {
                EmptyHistoryCard()
            } else {
                ForEach(store.sessions) { session in
                    HistorySessionRow(
                        session: session,
                        isActive: store.activeSessionID == session.id,
                        onSelect: {
                            ConversationStore.shared.selectSession(id: session.id)
                            onConversationSelected?()
                        }
                    )
                }
            }
        }
    }

    private var primaryProviderLabel: String {
        guard let identifier = store.configuredProvidersInHistory
            .max(by: { $0.value < $1.value })?
            .key else {
            return "None"
        }

        return AIProvider(rawValue: identifier)?.displayName ?? identifier
    }
}

private struct HistoryStatCard: View {
    let title: String
    let value: String
    let subtitle: String

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(theme.appFont(size: 11, weight: .semibold))
                .foregroundColor(theme.onSurface.opacity(0.45))

            Text(value)
                .font(theme.appFont(size: 24, weight: .bold))
                .foregroundColor(theme.onSurface)

            Text(subtitle)
                .font(theme.appFont(size: 13))
                .foregroundColor(theme.onSurface.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(theme.surfaceContainer)
        .cornerRadius(26)
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(theme.outlineVariant.opacity(0.15), lineWidth: 1)
        )
    }
}

private struct HistorySessionRow: View {
    let session: ChatSession
    let isActive: Bool
    let onSelect: () -> Void

    @ObservedObject private var theme = ThemeManager.shared

    private static let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.title)
                            .font(theme.appFont(size: 18, weight: .semibold))
                            .foregroundColor(theme.onSurface)
                            .multilineTextAlignment(.leading)

                        Text(session.previewText)
                            .font(theme.appFont(size: 13))
                            .foregroundColor(theme.onSurface.opacity(0.62))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }

                    Spacer()

                    if isActive {
                        Text("Active")
                            .font(theme.appFont(size: 12, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(theme.primary)
                            .cornerRadius(12)
                    }
                }

                HStack {
                    Text(providerLabel)
                        .font(theme.appFont(size: 12))
                        .foregroundColor(theme.primary)

                    Spacer()

                    Text(Self.dateFormatter.localizedString(for: session.updatedAt, relativeTo: Date()))
                        .font(theme.appFont(size: 12))
                        .foregroundColor(theme.onSurface.opacity(0.45))
                }
            }
            .padding(18)
            .background(theme.surfaceContainer)
            .cornerRadius(26)
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(
                        isActive ? theme.primary.opacity(0.35) : theme.outlineVariant.opacity(0.15),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var providerLabel: String {
        guard let modelName = session.modelName else {
            return "Unassigned model"
        }

        let providerName = session.providerID
            .flatMap { AIProvider(rawValue: $0)?.displayName }
            ?? "AI"

        return "\(providerName) - \(modelName)"
    }
}

private struct EmptyHistoryCard: View {
    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No saved conversations yet.")
                .font(theme.appFont(size: 16, weight: .semibold))
                .foregroundColor(theme.onSurface)

            Text("Start chatting and your sessions will appear here automatically.")
                .font(theme.appFont(size: 14))
                .foregroundColor(theme.onSurface.opacity(0.62))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(theme.surfaceContainer)
        .cornerRadius(24)
    }
}

private struct SmallActionButton: View {
    let label: String
    let systemImage: String
    let action: () -> Void

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(label)
                    .font(theme.appFont(size: 14, weight: .semibold))
            }
            .foregroundColor(theme.onSurface)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(theme.surfaceContainerLow)
            .cornerRadius(18)
        }
        .buttonStyle(.plain)
    }
}
