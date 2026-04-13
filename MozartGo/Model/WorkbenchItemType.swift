//
//  WorkbenchItemType.swift
//  MozartGo
//
//  Created by apexa Chovatiya on 09/04/26.
//


import Foundation
// MARK: - Workbench

enum WorkbenchItemType: String, Codable {
    case file, folder
}

struct WorkbenchItem: Codable, Identifiable {
    let id: String
    let name: String
    let type: WorkbenchItemType
    let content: String?
    let createdAt: Date?
    let updatedAt: Date?
    let parentId: String?

    enum CodingKeys: String, CodingKey {
        case id, name, type, content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case parentId = "parent_id"
    }
}