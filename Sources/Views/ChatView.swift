import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Cognitive Ether")
                    .font(theme.appFont(size: 24, weight: .bold))
                    .foregroundColor(theme.onSurface)
                Spacer()
                Image(systemName: "cpu")
                    .foregroundColor(theme.primary)
            }
            .padding()
            .background(theme.surface.opacity(0.8))
            .blur(radius: 0)
            
            // Message List
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages) { _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input Area
            HStack(spacing: 12) {
                Button(action: {
                    // Action for attachments
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(theme.onSurface.opacity(0.6))
                        .frame(width: 44, height: 44)
                        .background(theme.surfaceContainerLow)
                        .clipShape(Circle())
                }
                
                TextField("Message Cognitive Ether...", text: $viewModel.inputText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(theme.surfaceContainerLow)
                    .cornerRadius(32)
                    .foregroundColor(theme.onSurface)
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(theme.primaryGradient)
                        .clipShape(Circle())
                }
                .disabled(viewModel.inputText.isEmpty)
                .opacity(viewModel.inputText.isEmpty ? 0.5 : 1.0)
            }
            .padding()
            .background(theme.surface.opacity(0.9))
        }
        .background(theme.surface.ignoresSafeArea())
    }
}

struct MessageBubble: View {
    let message: Message
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                if message.role == .reasoning {
                    ReasoningAccord(content: message.content)
                } else {
                    Text(message.content)
                        .font(theme.appFont(size: 16))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .foregroundColor(theme.onSurface)
                        .background(
                            message.role == .user 
                            ? theme.surfaceContainerHighest
                            : Color.clear
                        )
                        .cornerRadius(30)
                        .overlay(
                            message.role == .assistant
                            ? RoundedRectangle(cornerRadius: 30)
                                .stroke(theme.outlineVariant.opacity(0.15), lineWidth: 1)
                            : nil
                        )
                }
            }
            
            if message.role != .user { Spacer() }
        }
    }
}

struct ReasoningAccord: View {
    let content: String
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(theme.primary)
                .frame(width: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Reasoning")
                    .font(theme.appFont(size: 14, weight: .semibold))
                    .foregroundColor(theme.onSurface.opacity(0.7))
                
                Text(content)
                    .font(theme.appFont(size: 14))
                    .foregroundColor(theme.onSurface.opacity(0.5))
            }
        }
        .padding(.vertical, 8)
    }
}
