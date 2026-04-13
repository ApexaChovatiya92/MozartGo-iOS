//
//  AuthResponse.swift
//  MozartGo
//
//  Created by apexa Chovatiya on 09/04/26.
//


import Foundation

// MARK: - Auth

struct AuthResponse: Codable {
    let token: String?
    let user: User?
    let error: String?
}

extension AuthResponse {
    static func mockSuccess(email: String) -> AuthResponse {
        return AuthResponse(
            token: UUID().uuidString,
            user: User(
                id: UUID().uuidString,
                email: email,
                name: "Test User"
            ),
            error: nil
        )
    }
}
