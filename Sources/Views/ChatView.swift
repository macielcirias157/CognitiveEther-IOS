import SwiftUI
import UIKit

struct ChatView: View {
    @ObservedObject private var viewModel = ChatViewModel.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var isShowingSettings = false
    @State private var isShowingHistory = false

    var body: some View {
        VStack(spacing: 0) {
            ChatHeader(
                title: viewModel.activeTitle,
                subtitle: viewModel.activeProviderLabel,
                isProcessing: viewModel.isProcessing,
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
                .onChange(of: viewModel.messages) { _ in
                    guard let lastID = viewModel.messages.last?.id else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }

            ChatComposer(
                text: $viewModel.inputText,
                isProcessing: viewModel.isProcessing,
                onSubmit: viewModel.sendMessage
            )
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
    }
}

private struct ChatHeader: View {
    let title: String
    let subtitle: String
    let isProcessing: Bool
    let onNewConversation: () -> Void
    let onOpenHistory: () -> Void
    let onOpenSettings: () -> Void

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
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

                HStack(spacing: 10) {
                    HeaderIconButton(systemImage: "clock.arrow.circlepath", action: onOpenHistory)
                    HeaderIconButton(systemImage: "square.and.pencil", action: onNewConversation)
                    HeaderIconButton(systemImage: "gearshape", action: onOpenSettings)
                }
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

private struct HeaderIconButton: View {
    let systemImage: String
    let action: () -> Void

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.onSurface.opacity(0.75))
                .frame(width: 40, height: 40)
                .background(theme.surfaceContainerLow)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

struct MessageBubble: View {
    let message: Message
    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 44) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                if message.role == .reasoning {
                    ReasoningAccord(content: message.content)
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

struct ReasoningAccord: View {
    let content: String
    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(theme.primary)
                .frame(width: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Execution Context")
                    .font(theme.appFont(size: 13, weight: .semibold))
                    .foregroundColor(theme.onSurface.opacity(0.7))

                Text(content)
                    .font(theme.appFont(size: 13))
                    .foregroundColor(theme.onSurface.opacity(0.5))
            }
        }
        .padding(.vertical, 8)
    }
}
