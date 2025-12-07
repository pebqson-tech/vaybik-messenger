//
//  MockService.swift
//  MessengerApp
//
//  Мок-сервис для тестирования без бэкенда
//

import Foundation

class MockService {
    static let shared = MockService()
    
    // Тестовые пользователи
    private let mockUsers: [User] = [
        User(id: "user1", name: "Анна Иванова", email: "anna@example.com", status: .online),
        User(id: "user2", name: "Петр Сидоров", email: "petr@example.com", status: .away),
        User(id: "user3", name: "Мария Петрова", email: "maria@example.com", status: .offline),
        User(id: "user4", name: "Иван Козлов", email: "ivan@example.com", status: .online),
        User(id: "user5", name: "Елена Смирнова", email: "elena@example.com", status: .online)
    ]
    
    // Тестовые чаты
    private var mockChats: [Chat] = []
    
    // Тестовые сообщения
    private var mockMessages: [String: [Message]] = [:]
    
    private init() {
        setupMockData()
    }
    
    private func setupMockData() {
        // Создаем тестовые чаты
        let currentUserID = "current_user"
        
        // Чат 1
        let chat1ID = "chat1"
        let chat1Messages = [
            Message(id: "msg1", chatID: chat1ID, senderID: "user1", text: "Привет! Как дела?", timestamp: Date().addingTimeInterval(-3600), status: .read),
            Message(id: "msg2", chatID: chat1ID, senderID: currentUserID, text: "Привет! Всё отлично, спасибо!", timestamp: Date().addingTimeInterval(-3500), status: .read),
            Message(id: "msg3", chatID: chat1ID, senderID: "user1", text: "Отлично! Давай встретимся завтра?", timestamp: Date().addingTimeInterval(-3400), status: .read),
            Message(id: "msg4", chatID: chat1ID, senderID: currentUserID, text: "Конечно! Во сколько?", timestamp: Date().addingTimeInterval(-3300), status: .delivered)
        ]
        mockMessages[chat1ID] = chat1Messages
        
        let chat1 = Chat(
            id: chat1ID,
            participants: [currentUserID, "user1"],
            lastMessage: chat1Messages.last,
            lastMessageDate: chat1Messages.last!.timestamp,
            unreadCount: 0,
            isPinned: true
        )
        
        // Чат 2
        let chat2ID = "chat2"
        let chat2Messages = [
            Message(id: "msg5", chatID: chat2ID, senderID: "user2", text: "Здравствуй!", timestamp: Date().addingTimeInterval(-7200), status: .read),
            Message(id: "msg6", chatID: chat2ID, senderID: currentUserID, text: "Привет! Что нового?", timestamp: Date().addingTimeInterval(-7100), status: .read),
            Message(id: "msg7", chatID: chat2ID, senderID: "user2", text: "Всё хорошо, работаю над проектом", timestamp: Date().addingTimeInterval(-7000), status: .read)
        ]
        mockMessages[chat2ID] = chat2Messages
        
        let chat2 = Chat(
            id: chat2ID,
            participants: [currentUserID, "user2"],
            lastMessage: chat2Messages.last,
            lastMessageDate: chat2Messages.last!.timestamp,
            unreadCount: 2,
            isPinned: false
        )
        
        // Чат 3
        let chat3ID = "chat3"
        let chat3Messages = [
            Message(id: "msg8", chatID: chat3ID, senderID: "user3", text: "Добрый день!", timestamp: Date().addingTimeInterval(-86400), status: .read),
            Message(id: "msg9", chatID: chat3ID, senderID: currentUserID, text: "Привет! Как настроение?", timestamp: Date().addingTimeInterval(-86000), status: .read)
        ]
        mockMessages[chat3ID] = chat3Messages
        
        let chat3 = Chat(
            id: chat3ID,
            participants: [currentUserID, "user3"],
            lastMessage: chat3Messages.last,
            lastMessageDate: chat3Messages.last!.timestamp,
            unreadCount: 0,
            isPinned: false
        )
        
        mockChats = [chat1, chat2, chat3]
    }
    
    // MARK: - Mock Data Getters
    
    func getMockUsers() -> [User] {
        return mockUsers
    }
    
    func getMockChats() -> [Chat] {
        return mockChats
    }
    
    func getMockMessages(for chatID: String) -> [Message] {
        return mockMessages[chatID] ?? []
    }
    
    func addMockMessage(_ message: Message, to chatID: String) {
        if mockMessages[chatID] == nil {
            mockMessages[chatID] = []
        }
        mockMessages[chatID]?.append(message)
        
        // Обновляем lastMessage в чате
        if let chatIndex = mockChats.firstIndex(where: { $0.id == chatID }) {
            mockChats[chatIndex].lastMessage = message
            mockChats[chatIndex].lastMessageDate = message.timestamp
        }
    }
    
    func createMockChat(with userID: String) -> Chat {
        let currentUserID = "current_user"
        let chatID = UUID().uuidString
        let newChat = Chat(
            id: chatID,
            participants: [currentUserID, userID],
            lastMessage: nil,
            lastMessageDate: Date(),
            unreadCount: 0
        )
        mockChats.append(newChat)
        mockMessages[chatID] = []
        return newChat
    }
    
    func searchMockUsers(query: String) -> [User] {
        let lowerQuery = query.lowercased()
        return mockUsers.filter { user in
            user.name.lowercased().contains(lowerQuery) ||
            user.email?.lowercased().contains(lowerQuery) ?? false
        }
    }
}

