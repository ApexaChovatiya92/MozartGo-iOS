import Foundation
import Combine

@MainActor
final class ComposeViewModel: ObservableObject {

    @Published var inputText = ""
    @Published var messages: [ChatMessage] = []
    @Published var isStreaming = false
    @Published var streamingText = ""
    @Published var errorMessage: String?
    @Published var conversationId: String?
    @Published var conversations: [Conversation] = []

    private let apiService: APIServiceProtocol
    private var streamTask: Task<Void, Never>?

    // ✅ Dependency Injection
    init(apiService: APIServiceProtocol = MockAPIService()) {
        self.apiService = apiService
    }

    // MARK: - Conversation

    func createOrContinueConversation() async {
        if conversationId == nil {
            do {
                let conv = try await apiService.createConversation(title: nil)
                conversationId = conv.id
            } catch {
                errorMessage = "Failed to create conversation: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Send Message

    func sendMessage() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userText = trimmed
        inputText = ""
        errorMessage = nil

        // Add user message immediately
        let userMsg = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: userText,
            createdAt: Date()
        )
        messages.append(userMsg)

        await createOrContinueConversation()
        guard let convId = conversationId else { return }

        // Save message (non-blocking UX)
        Task {
            try? await apiService.createMessage(conversationId: convId, content: userText)
        }

        // Start streaming
        isStreaming = true
        streamingText = ""

        streamTask?.cancel()

        streamTask = Task {
            do {
                let stream = try await apiService.streamCompletion(
                    conversationId: convId,
                    prompt: userText
                )

                for try await token in stream {
                    if Task.isCancelled { return }
                    streamingText += token
                }

                // Final assistant message
                let assistantMsg = ChatMessage(
                    id: UUID().uuidString,
                    role: .assistant,
                    content: streamingText,
                    createdAt: Date()
                )

                messages.append(assistantMsg)
                streamingText = ""

            } catch {
                if !Task.isCancelled {
                    errorMessage = "Streaming failed: \(error.localizedDescription)"
                    streamingText = ""
                }
            }

            isStreaming = false
        }
    }

    // MARK: - Cancel

    func cancelStreaming() {
        streamTask?.cancel()
        streamTask = nil

        if !streamingText.isEmpty {
            let partial = ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                content: streamingText + " _(cancelled)_",
                createdAt: Date()
            )
            messages.append(partial)
        }

        streamingText = ""
        isStreaming = false
    }

    // MARK: - Conversations

    func loadConversations() async {
        do {
            conversations = try await apiService.getConversations()
            CacheService.shared.cacheConversations(conversations)
        } catch {
            let cached = CacheService.shared.loadCachedConversations()
            if !cached.isEmpty {
                conversations = cached
            }
        }
    }

    func loadMessages(for conversationId: String) async {
        do {
            self.conversationId = conversationId
            messages = try await apiService.getMessages(conversationId: conversationId)
        } catch {
            errorMessage = "Failed to load messages."
        }
    }
}
