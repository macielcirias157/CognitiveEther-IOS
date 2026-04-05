import SwiftUI
import UIKit

struct ChatView: View {
    @ObservedObject private var viewModel = ChatViewModel.shared
    @ObservedObject private var theme = ThemeManager.shared
    @FocusState private var isInputFocused: Bool

    @State private var isShowingSettings = false
    @State private var isShowingHistory = false
    @State private var showingMenu = false

    var body: some View {
        VStack(spacing: 0) {
            ChatHeader(
                title: viewModel.activeTitle,
                subtitle: viewModel.activeProviderLabel,
                isProcessing: viewModel.isProcessing,
                onMenuToggle: { showingMenu = true },
                onNewConversation: viewModel.createNewConversation,
                onOpenHistory: { isShowingHistory = true },
                onOpenSettings: { isShowingSettings = true }
            )

            Divider()
                .overlay(theme.outlineVariant.opacity(0.15))

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    guard let lastID = viewModel.messages.last?.id else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
                .onTapGesture {
                    hideKeyboard()
                }
            }

            ChatComposer(
                text: $viewModel.inputText,
                isProcessing: viewModel.isProcessing,
                onSubmit: {
                    viewModel.sendMessage()
                }
            )
            .focused($isInputFocused)
        }
        .background(theme.surface.ignoresSafeArea())
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                SettingsView()
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $isShowingHistory) {
            NavigationStack {
                HistoryView {
                    isShowingHistory = false
                }
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Actions", isPresented: $showingMenu) {
            Button("New Conversation") {
                viewModel.createNewConversation()
            }
            Button("History") {
                isShowingHistory = true
            }
            Button("Settings") {
                isShowingSettings = true
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct ChatHeader: View {
    let title: String
    let subtitle: String
    let isProcessing: Bool
    let onMenuToggle: () -> Void
    let onNewConversation: () -> Void
    let onOpenHistory: () -> Void
    let onOpenSettings: () -> Void

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                Button(action: onMenuToggle) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.onSurface)
                        .frame(width: 44, height: 44)
                        .background(theme.surfaceContainerLow)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(theme.appFont(size: 24, weight: .bold))
                        .foregroundColor(theme.onSurface)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(theme.appFont(size: 13))
                        .foregroundColor(theme.onSurface.opacity(0.58))
                        .lineLimit(1)
                }

                Spacer()
            }

            if isProcessing {
                HStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                    Text("Generating response...")
                        .font(theme.appFont(size: 13))
                        .foregroundColor(theme.onSurface.opacity(0.65))
                    Spacer()
                }
            }
        }
        .padding()
        .background(theme.surface.opacity(0.94))
    }
}

private struct ChatComposer: View {
    @Binding var text: String
    let isProcessing: Bool
    let onSubmit: () -> Void

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        HStack(spacing: 12) {
            TextField("Message Cognitive Ether...", text: $text, axis: .vertical)
                .lineLimit(1...6)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(theme.surfaceContainerLow)
                .cornerRadius(24)
                .foregroundColor(theme.onSurface)
                .disabled(isProcessing)
                .onSubmit(onSubmit)

            Button(action: onSubmit) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 46, height: 46)
                    .background(theme.primaryGradient)
                    .clipShape(Circle())
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing ? 0.45 : 1)
        }
        .padding()
        .background(theme.surface.opacity(0.96))
    }
}

struct MessageBubble: View {
    let message: Message
    @ObservedObject private var theme = ThemeManager.shared
    @State private var isExpanded: Bool = true

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 44) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                if message.role == .reasoning {
                    ThinkingBlock(content: message.content, isExpanded: $isExpanded)
                } else {
                    Text(message.content)
                        .font(theme.appFont(size: 16))
                        .foregroundColor(theme.onSurface)
                        .multilineTextAlignment(message.role == .user ? .trailing : .leading)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(message.role == .user ? theme.surfaceContainerHighest : theme.surfaceContainer)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    message.role == .assistant
                                        ? theme.outlineVariant.opacity(0.15)
                                        : Color.clear,
                                    lineWidth: 1
                                )
                        )
                        .contextMenu {
                            Button("Copy") {
                                UIPasteboard.general.string = message.content
                            }
                        }

                    Text(timestampLabel)
                        .font(theme.appFont(size: 11))
                        .foregroundColor(theme.onSurface.opacity(0.38))
                }
            }

            if message.role != .user { Spacer(minLength: 44) }
        }
    }

    private var timestampLabel: String {
        message.timestamp.formatted(date: .omitted, time: .shortened)
    }
}

struct ThinkingBlock: View {
    let content: String
    @Binding var isExpanded: Bool
    @ObservedObject private var theme = ThemeManager.shared
    
    @State private var currentSize: ThinkingSize = .medium

    private var fontSize: CGFloat {
        switch currentSize {
        case .small: return 11
        case .medium: return 13
        case .large: return 15
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() } }) {
                HStack(spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.electricIndigo)

                    Text("Thinking")
                        .font(theme.appFont(size: 14, weight: .semibold))
                        .foregroundColor(theme.electricIndigo)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.onSurface.opacity(0.5))
                    
                    Menu {
                        ForEach(ThinkingSize.allCases, id: \.self) { size in
                            Button {
                                currentSize = size
                            } label: {
                                HStack {
                                    Text(size.label)
                                    if currentSize == size {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "textformat.size")
                            .font(.system(size: 14))
                            .foregroundColor(theme.onSurface.opacity(0.5))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(theme.surfaceContainerHigh)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView {
                    Text(content)
                        .font(theme.appFont(size: fontSize))
                        .foregroundColor(theme.onSurface.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .frame(maxHeight: currentSize.maxHeight)
                .background(theme.surfaceContainer.opacity(0.5))
            }
        }
        .background(theme.surfaceContainer)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.electricIndigo.opacity(0.3), lineWidth: 1)
        )
    }
}

enum ThinkingSize: String, CaseIterable {
    case small
    case medium
    case large
    
    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
    
    var maxHeight: CGFloat {
        switch self {
        case .small: return 80
        case .medium: return 150
        case .large: return 300
        }
    }
}