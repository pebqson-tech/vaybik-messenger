//
//  User.swift
//  MessengerApp
//
//  Модель пользователя
//

import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var username: String?
    var email: String?
    var avatarURL: String?
    var status: UserStatus
    var lastSeen: Date?
    
    enum UserStatus: String, Codable {
        case online
        case offline
        case away
    }
    
    init(id: String = UUID().uuidString, 
         name: String,
         username: String? = nil,
         email: String? = nil, 
         avatarURL: String? = nil,
         status: UserStatus = .offline,
         lastSeen: Date? = nil) {
        self.id = id
        self.name = name
        self.username = username
        self.email = email
        self.avatarURL = avatarURL
        self.status = status
        self.lastSeen = lastSeen
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case username
        case email
        case avatarURL = "avatar_url"
        case status
        case lastSeen = "last_seen"
    }
}

// Расширение для текущего пользователя
extension User {
    static var current: User? {
        get {
            if let data = UserDefaults.standard.data(forKey: "currentUser"),
               let user = try? JSONDecoder().decode(User.self, from: data) {
                return user
            }
            return nil
        }
        set {
            if let user = newValue,
               let data = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(data, forKey: "currentUser")
            } else {
                UserDefaults.standard.removeObject(forKey: "currentUser")
            }
        }
    }
}

