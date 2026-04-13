//
//  Conversation.swift
//  MozartGo
//
//  Created by apexa Chovatiya on 09/04/26.
//


import Foundation

// MARK: - Conversation

struct Conversation: Codable, Identifiable {
    let id: String
    let title: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
