import SwiftUI

struct ComposeView: View {
    @StateObject private var vm = ComposeViewModel()
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var showConversationList = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0A0A0F").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Offline banner
                    if !networkMonitor.isConnected {
                        OfflineBanner(message: "Offline — responses unavailable")
                    }

                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if vm.messages.isEmpty && !vm.isStreaming {
                                    EmptyComposeState()
                                        .padding(.top, 60)
                                }

                                ForEach(vm.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }

                                // Streaming bubble
                                if vm.isStreaming || !vm.streamingText.isEmpty {
                                    StreamingBubble(text: vm.streamingText)
                                        .id("streaming")
                                }

                                Color.clear.frame(height: 1).id("bottom")
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }
                        .onChange(of: vm.messages.count) { _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onChange(of: vm.streamingText) { _ in
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }

                    // Error
                    if let error = vm.errorMessage {
                        ErrorBanner(message: error) {
                            vm.errorMessage = nil
                        }
                    }

                    // Input bar
                    ComposeInputBar(
                        text: $vm.inputText,
                        isStreaming: vm.isStreaming,
                        isOffline: !networkMonitor.isConnected,
                        isFocused: _inputFocused,
                        onSend: {
                            Task { await vm.sendMessage() }
                        },
                        onCancel: { vm.cancelStreaming() }
                    )
                }
            }
            .navigationTitle("Compose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showConversationList = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(Color(hex: "#9B6FF5"))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.messages = []
                        vm.conversationId = nil
                        vm.streamingText = ""
                        vm.errorMessage = nil
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(Color(hex: "#9B6FF5"))
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(hex: "#0E0E16"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showConversationList) {
                ConversationListSheet(vm: vm)
            }
        }
        .task { await vm.loadConversations() }
    }
}

// MARK: - Empty State

struct EmptyComposeState: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#7C4FE4").opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "#9B6FF5"))
            }

            VStack(spacing: 8) {
                Text("Start Composing")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("Ask anything. Mozart streams\nreal-time AI responses.")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Suggestion chips
            VStack(spacing: 8) {
                ForEach([
                    "Summarize my latest project",
                    "Draft a technical document",
                    "Explain this concept clearly"
                ], id: \.self) { suggestion in
                    Text(suggestion)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#9B6FF5"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#7C4FE4").opacity(0.1))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#7C4FE4").opacity(0.25), lineWidth: 1)
                        )
                }
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            if !isUser {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "#7C4FE4"), Color(hex: "#4F2FC4")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 28, height: 28)
                    Text("M")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(isUser ? .white : Color.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isUser
                        ? LinearGradient(
                            colors: [Color(hex: "#7C4FE4"), Color(hex: "#5A32C8")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.06)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16, corners: isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])

                Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundColor(Color.white.opacity(0.25))
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Streaming Bubble

struct StreamingBubble: View {
    let text: String
    @State private var dotPhase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "#7C4FE4"), Color(hex: "#4F2FC4")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 28, height: 28)
                Text("M")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            if text.isEmpty {
                // Typing indicator
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 6, height: 6)
                            .scaleEffect(dotPhase == i ? 1.3 : 0.8)
                            .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15), value: dotPhase)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.07))
                .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                .onAppear { dotPhase = 2 }
            } else {
                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(Color.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.07))
                    .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                    .overlay(alignment: .bottomTrailing) {
                        // Cursor blink
                        Rectangle()
                            .fill(Color(hex: "#9B6FF5"))
                            .frame(width: 2, height: 14)
                            .padding(.trailing, 4)
                            .padding(.bottom, 4)
                    }
            }

            Spacer(minLength: 60)
        }
    }
}

// MARK: - Input Bar

struct ComposeInputBar: View {
    @Binding var text: String
    let isStreaming: Bool
    let isOffline: Bool
    @FocusState var isFocused: Bool
    let onSend: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider().background(Color.white.opacity(0.06))

            HStack(spacing: 12) {
                // Attachment placeholder
                Button {
                    // attachment picker
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 18))
                        .foregroundColor(Color.white.opacity(0.4))
                        .frame(width: 36, height: 36)
                }

                // Text input
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text("Ask Mozart anything…")
                            .font(.system(size: 15))
                            .foregroundColor(Color.white.opacity(0.25))
                    }
                    TextEditor(text: $text)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .frame(minHeight: 36, maxHeight: 120)
                        .scrollContentBackground(.hidden)
                        .focused($isFocused)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.07))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color(hex: "#7C4FE4").opacity(0.5) : Color.clear, lineWidth: 1)
                )

                // Send/Cancel button
                Button {
                    if isStreaming {
                        onCancel()
                    } else {
                        onSend()
                    }
                } label: {
                    Image(systemName: isStreaming ? "stop.fill" : "arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            isStreaming
                            ? Color(hex: "#FF6B6B")
                            : (text.isEmpty || isOffline
                               ? Color.white.opacity(0.15)
                               : Color(hex: "#7C4FE4"))
                        )
                        .cornerRadius(10)
                }
                .disabled(text.isEmpty && !isStreaming || isOffline && !isStreaming)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(hex: "#0E0E16"))
        }
    }
}

// MARK: - Conversation List Sheet

struct ConversationListSheet: View {
    @ObservedObject var vm: ComposeViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0A0A0F").ignoresSafeArea()

                if vm.conversations.isEmpty {
                    Text("No previous conversations")
                        .foregroundColor(Color.white.opacity(0.4))
                        .font(.system(size: 15))
                } else {
                    List {
                        ForEach(vm.conversations) { conv in
                            Button {
                                Task {
                                    await vm.loadMessages(for: conv.id)
                                    dismiss()
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(conv.title ?? "Conversation")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                    if let date = conv.createdAt {
                                        Text(date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.white.opacity(0.4))
                                    }
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.04))
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#9B6FF5"))
                }
            }
            .toolbarBackground(Color(hex: "#0E0E16"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Shared UI Helpers

struct OfflineBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 12))
            Text(message)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(hex: "#E87B3C").opacity(0.85))
    }
}

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
            Text(message)
                .font(.system(size: 13))
            Spacer()
            Button { onDismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
            }
        }
        .foregroundColor(Color(hex: "#FF6B6B"))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "#FF6B6B").opacity(0.1))
        .padding(.horizontal, 12)
    }
}

// MARK: - Corner Radius Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
