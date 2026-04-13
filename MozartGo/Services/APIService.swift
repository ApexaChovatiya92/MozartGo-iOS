//
//  APIService.swift
//  MozartGo
//
//  Created by apexa Chovatiya on 08/04/26.
//
import Foundation
protocol APIServiceProtocol {
    func signIn(email: String, password: String) async throws -> AuthResponse
    func signUp(name: String, email: String, password: String) async throws -> AuthResponse
    func getCurrentUser() async throws -> User

    func createConversation(title: String?) async throws -> Conversation
    func getConversations() async throws -> [Conversation]
    func getMessages(conversationId: String) async throws -> [ChatMessage]
    func createMessage(conversationId: String, content: String) async throws -> ChatMessage

    func getFolderContents(folderId: String?) async throws -> [WorkbenchItem]
    func deleteFile(id: String) async throws
    func deleteFolder(id: String) async throws
    
    func streamCompletion(conversationId: String, prompt: String) async throws -> AsyncThrowingStream<String, Error>
}

final class APIService: APIServiceProtocol {
    static let shared = APIService()
    private init() {}

    private let baseURL = "https://dev.mozart.la"//"https://api-dev.mozart.la"
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let formatters: [ISO8601DateFormatter] = [
                { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f }(),
                { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime]; return f }()
            ]
            for fmt in formatters {
                if let date = fmt.date(from: str) { return date }
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot parse date: \(str)")
        }
        return d
    }()

    // MARK: - Auth

    func signIn(email: String, password: String) async throws -> AuthResponse {
        let body = ["email": email, "password": password]
        return try await post(path: "/api/v1/auth/sign-in", body: body, requiresAuth: false)
    }

    func signUp(name: String, email: String, password: String) async throws -> AuthResponse {
        let body = ["name": name, "email": email, "password": password]
        return try await post(path: "/api/v1/auth/sign-up", body: body, requiresAuth: false)
    }

    func getCurrentUser() async throws -> User {
        let wrapper: APISingleResponse<User> = try await get(path: "/api/v1/user/get")
        guard let user = wrapper.data else {
            throw APIError.unknown(wrapper.error ?? "No user data")
        }
        return user
    }

    // MARK: - Conversations

    func createConversation(title: String? = nil) async throws -> Conversation {
        let body: [String: String?] = ["title": title]
        let wrapper: APISingleResponse<Conversation> = try await post(path: "/api/v1/conversation/create", body: body)
        guard let conv = wrapper.data else {
            throw APIError.unknown(wrapper.error ?? "Failed to create conversation")
        }
        return conv
    }

    func getConversations() async throws -> [Conversation] {
        let wrapper: APIListResponse<Conversation> = try await get(path: "/api/v1/conversation/get")
        return wrapper.results
    }

    func getMessages(conversationId: String) async throws -> [ChatMessage] {
        let wrapper: APIListResponse<ChatMessage> = try await get(path: "/api/v1/message/getById?conversationId=\(conversationId)")
        return wrapper.results
    }

    func createMessage(conversationId: String, content: String) async throws -> ChatMessage {
        let body = ["conversationId": conversationId, "content": content, "role": "user"]
        let wrapper: APISingleResponse<ChatMessage> = try await post(path: "/api/v1/message/create", body: body)
        guard let msg = wrapper.data else {
            throw APIError.unknown(wrapper.error ?? "Failed to create message")
        }
        return msg
    }

    // MARK: - Workbench

    func getFolderContents(folderId: String? = nil) async throws -> [WorkbenchItem] {
        let path = folderId != nil
            ? "/api/v1/folder/getFolderContents/\(folderId!)"
            : "/api/v1/folder/getFolderContents/root"
        let wrapper: APIListResponse<WorkbenchItem> = try await get(path: path)
        return wrapper.results
    }

    func deleteFile(id: String) async throws {
        let body = ["id": id]
        let _: APISingleResponse<WorkbenchItem> = try await post(path: "/api/v1/file/delete", body: body)
    }

    func deleteFolder(id: String) async throws {
        let body = ["id": id]
        let _: APISingleResponse<WorkbenchItem> = try await post(path: "/api/v1/folder/delete", body: body)
    }

    // MARK: - Streaming Completions

    func streamCompletion(conversationId: String, prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        guard let url = URL(string: baseURL + "/api/v1/completions") else {
            throw APIError.unknown("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        if let token = KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body = ["conversationId": conversationId, "prompt": prompt, "stream": true] as [String: Any]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    guard let httpResp = response as? HTTPURLResponse else {
                        continuation.finish(throwing: APIError.unknown("Invalid response"))
                        return
                    }
                    if httpResp.statusCode == 401 {
                        continuation.finish(throwing: APIError.unauthorized)
                        return
                    }
                    if httpResp.statusCode >= 400 {
                        continuation.finish(throwing: APIError.serverError(httpResp.statusCode))
                        return
                    }

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let data = String(line.dropFirst(6))
                            if data == "[DONE]" {
                                continuation.finish()
                                return
                            }
                            if let jsonData = data.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                                // OpenAI-style SSE: choices[0].delta.content
                                if let choices = json["choices"] as? [[String: Any]],
                                   let delta = choices.first?["delta"] as? [String: Any],
                                   let token = delta["content"] as? String {
                                    continuation.yield(token)
                                }
                                // Simple style: { "token": "..." }
                                else if let token = json["token"] as? String {
                                    continuation.yield(token)
                                }
                                // text field
                                else if let text = json["text"] as? String {
                                    continuation.yield(text)
                                }
                            } else if !data.isEmpty {
                                continuation.yield(data)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Generic HTTP Methods

    private func get<T: Decodable>(path: String) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.unknown("Invalid URL: \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuthHeader(&request)
        return try await perform(request: request)
    }

    private func post<T: Decodable, B: Encodable>(path: String, body: B, requiresAuth: Bool = true) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.unknown("Invalid URL: \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if requiresAuth { addAuthHeader(&request) }

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        return try await perform(request: request)
    }

    private func addAuthHeader(_ request: inout URLRequest) {
        if let token = KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func perform<T: Decodable>(request: URLRequest, retries: Int = 2) async throws -> T {
        var lastError: Error?
        for attempt in 0...retries {
            do {
                if attempt > 0 {
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000)
                }
                let (data, response) = try await session.data(for: request)
                guard let httpResp = response as? HTTPURLResponse else {
                    throw APIError.unknown("Non-HTTP response")
                }
                switch httpResp.statusCode {
                case 200...299:
                    return try decoder.decode(T.self, from: data)
                case 401:
                    throw APIError.unauthorized
                case 404:
                    throw APIError.notFound
                case 500...599:
                    throw APIError.serverError(httpResp.statusCode)
                default:
                    throw APIError.serverError(httpResp.statusCode)
                }
            } catch let e as APIError where e != .unauthorized {
                lastError = e
                continue
            } catch {
                throw error
            }
        }
        throw lastError ?? APIError.unknown("Max retries exceeded")
    }
}



// Make APIError equatable for pattern matching
extension APIError: Equatable {
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized): return true
        case (.notFound, .notFound): return true
        default: return false
        }
    }
}
