//
//  User.swift
//  MozartGo
//
//  Created by apexa Chovatiya on 09/04/26.
//


import Foundation

// MARK: - User

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
}