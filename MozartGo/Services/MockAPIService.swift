//
//  MockAPIService.swift
//  MozartGo
//
//  Created by apexa Chovatiya on 08/04/26.
//

import Foundation

final class MockAPIService: APIServiceProtocol {

    private var storedUser = User(id: "1", email: "demo@mozart.la", name: "Demo User")
    private var conversations: [Conversation] = []
    private var messages: [String: [ChatMessage]] = [:]
    private var workbenchItems: [WorkbenchItem] = [
        // Root folders
        WorkbenchItem(
            id: "folder_1",
            name: "Documents",
            type: .folder,
            content: nil,
            createdAt: Date(),
            updatedAt: Date(),
            parentId: nil
        ),
        WorkbenchItem(
            id: "folder_2",
            name: "Projects",
            type: .folder,
            content: nil,
            createdAt: Date(),
            updatedAt: Date(),
            parentId: nil
        ),

        // Root files
        WorkbenchItem(
            id: "file_1",
            name: "Welcome.txt",
            type: .file,
            content: "Welcome to Mozart Go 🚀",
            createdAt: Date(),
            updatedAt: Date(),
            parentId: nil
        ),

        // Inside Documents
        WorkbenchItem(
            id: "file_2",
            name: "Notes.txt",
            type: .file,
            content: "Some notes...",
            createdAt: Date(),
            updatedAt: Date(),
            parentId: "folder_1"
        ),

        // Inside Projects
        WorkbenchItem(
            id: "file_3",
            name: "Plan.md",
            type: .file,
            content: "Project planning...",
            createdAt: Date(),
            updatedAt: Date(),
            parentId: "folder_2"
        )
    ]
    // MARK: - Auth

    func signIn(email: String, password: String) async throws -> AuthResponse {
        try await Task.sleep(nanoseconds: 800_000_000)
        storedUser = User(id: UUID().uuidString, email: email, name: email)

        return AuthResponse(
            token: "mock_jwt_token_123",
            user: storedUser,
            error: nil
        )
    }

    func signUp(name: String, email: String, password: String) async throws -> AuthResponse {
        try await Task.sleep(nanoseconds: 800_000_000)

        storedUser = User(id: UUID().uuidString, email: email, name: name)

        return AuthResponse(
            token: "mock_jwt_token_123",
            user: storedUser,
            error: nil
        )
    }

    func getCurrentUser() async throws -> User {
        storedUser
    }

    // MARK: - Conversations

    func createConversation(title: String?) async throws -> Conversation {
        let conv = Conversation(
            id: UUID().uuidString,
            title: title ?? "New Chat",
            createdAt: .now, updatedAt: nil
        )
        conversations.append(conv)
        return conv
    }

    func getConversations() async throws -> [Conversation] {
        conversations
    }

    func getMessages(conversationId: String) async throws -> [ChatMessage] {
        messages[conversationId] ?? []
    }

    func createMessage(conversationId: String, content: String) async throws -> ChatMessage {
        let msg = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: content,
            createdAt: .now
        )

        messages[conversationId, default: []].append(msg)
        return msg
    }
    
    // MARK: - Workbench (🔥 Important for your app)

    func getFolderContents(folderId: String?) async throws -> [WorkbenchItem] {
        try await Task.sleep(nanoseconds: 400_000_000)

        return workbenchItems.filter { item in
            item.parentId == folderId
        }
    }

    func deleteFile(id: String) async throws {
        workbenchItems.removeAll {
            $0.id == id && $0.type == .file
        }
    }
    
    func deleteFolder(id: String) async throws {
        // remove folder + all children recursively
        removeFolderAndChildren(folderId: id)
    }

    private func removeFolderAndChildren(folderId: String) {
        let children = workbenchItems.filter { $0.parentId == folderId }

        for child in children {
            if child.type == .folder {
                removeFolderAndChildren(folderId: child.id)
            }
            workbenchItems.removeAll { $0.id == child.id }
        }

        workbenchItems.removeAll { $0.id == folderId }
    }
    // MARK: - Streaming (🔥 Important for your app)

    func streamCompletion(conversationId: String, prompt: String) async throws -> AsyncThrowingStream<String, Error> {

        let response = "This is a mock AI response for: \(prompt)"

        return AsyncThrowingStream { continuation in
            Task {
                for word in response.split(separator: " ") {
                    try await Task.sleep(nanoseconds: 150_000_000)
                    continuation.yield(word + " ")
                }
                continuation.finish()
            }
        }
    }
}
