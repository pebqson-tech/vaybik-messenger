//
//  Message.swift
//  MessengerApp
//
//  Модель сообщения
//

import Foundation

struct Message: Identifiable, Codable, Hashable {
    let id: String
    let chatID: String
    let senderID: String
    var text: String?
    var imageURL: String?
    var fileURL: String?
    let timestamp: Date
    var isRead: Bool
    var status: MessageStatus
    
    enum CodingKeys: String, CodingKey {
        case id
        case chatID = "chatId"
        case senderID = "senderId"
        case text
        case imageURL = "image_url"
        case fileURL = "file_url"
        case timestamp
        case isRead = "is_read"
        case status
    }
    
    enum MessageStatus: String, Codable {
        case sending
        case sent
        case delivered
        case read
        case failed
    }
    
    enum MessageType: String, Codable {
        case text
        case image
        case file
    }
    
    var type: MessageType {
        if imageURL != nil {
            return .image
        } else if fileURL != nil {
            return .file
        }
        return .text
    }
    
    init(id: String = UUID().uuidString,
         chatID: String,
         senderID: String,
         text: String? = nil,
         imageURL: String? = nil,
         fileURL: String? = nil,
         timestamp: Date = Date(),
         isRead: Bool = false,
         status: MessageStatus = .sending) {
        self.id = id
        self.chatID = chatID
        self.senderID = senderID
        self.text = text
        self.imageURL = imageURL
        self.fileURL = fileURL
        self.timestamp = timestamp
        self.isRead = isRead
        self.status = status
    }
}

// Расширение для форматирования времени
extension Message {
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
    
    var dateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(timestamp) {
            return "Сегодня"
        } else if calendar.isDateInYesterday(timestamp) {
            return "Вчера"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            return formatter.string(from: timestamp)
        }
    }
}

