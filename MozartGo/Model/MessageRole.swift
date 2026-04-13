//
//  MessageRole.swift
//  MozartGo
//
//  Created by apexa Chovatiya on 09/04/26.
//


import Foundation


// MARK: - Chat Message

enum MessageRole: String, Codable {
    case user, assistant, system
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, role, content
        case createdAt = "created_at"
    }
}