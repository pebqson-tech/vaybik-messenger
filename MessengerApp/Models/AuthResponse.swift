//
//  AuthResponse.swift
//  MessengerApp
//
//  Ответ от API при авторизации
//

import Foundation

struct AuthResponse: Codable {
    let user: User
    let token: String
}

