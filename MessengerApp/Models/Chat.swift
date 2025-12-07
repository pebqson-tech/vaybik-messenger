//
//  Chat.swift
//  MessengerApp
//
//  Модель чата
//

import Foundation

struct Chat: Identifiable, Codable, Hashable {
    let id: String
    var participants: [String] // User IDs
    var lastMessage: LastMessage?
    var lastMessageDate: Date
    var unreadCount: Int
    var isPinned: Bool
    var createdAt: Date
    
    struct LastMessage: Codable, Hashable {
        let id: String
        let text: String
        let timestamp: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case text
            case timestamp
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            text = try container.decode(String.self, forKey: .text)
            
            // Декодируем timestamp из миллисекунд
            if let timestamp = try? container.decode(Int64.self, forKey: .timestamp) {
                self.timestamp = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
            } else {
                self.timestamp = Date()
            }
        }
    }
    
    init(id: String = UUID().uuidString,
         participants: [String],
         lastMessage: LastMessage? = nil,
         lastMessageDate: Date = Date(),
         unreadCount: Int = 0,
         isPinned: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.participants = participants
        self.lastMessage = lastMessage
        self.lastMessageDate = lastMessageDate
        self.unreadCount = unreadCount
        self.isPinned = isPinned
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case participants
        case lastMessage
        case lastMessageDate
        case unreadCount
        case isPinned
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        participants = try container.decode([String].self, forKey: .participants)
        lastMessage = try container.decodeIfPresent(LastMessage.self, forKey: .lastMessage)
        
        // Декодируем даты из timestamp (миллисекунды)
        if let timestamp = try? container.decode(Int64.self, forKey: .lastMessageDate) {
            lastMessageDate = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
        } else {
            lastMessageDate = Date()
        }
        
        if let timestamp = try? container.decode(Int64.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
        } else {
            createdAt = Date()
        }
        
        unreadCount = try container.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }
    
    // Получить ID собеседника
    func otherParticipantID(currentUserID: String) -> String? {
        return participants.first { $0 != currentUserID }
    }
}

