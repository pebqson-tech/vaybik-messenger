//
//  StorageService.swift
//  MessengerApp
//
//  Локальное хранилище для кэширования данных
//

import Foundation
import Combine

class StorageService: ObservableObject {
    static let shared = StorageService()
    
    @Published var chats: [Chat] = []
    @Published var messages: [String: [Message]] = [:] // [chatID: [messages]]
    @Published var users: [String: User] = [:] // [userID: user]
    
    private let chatsKey = "cached_chats"
    private let messagesKey = "cached_messages"
    private let usersKey = "cached_users"
    
    private let networkService = NetworkService.shared
    
    private init() {
        loadCachedData()
        // Загружаем тестовых пользователей в хранилище при инициализации
        if networkService.useMockData {
            let mockUsers = MockService.shared.getMockUsers()
            for user in mockUsers {
                saveUser(user)
            }
        }
    }
    
    // MARK: - Chats
    
    func saveChats(_ chats: [Chat]) {
        self.chats = chats
        cacheChats(chats)
    }
    
    func addChat(_ chat: Chat) {
        if !chats.contains(where: { $0.id == chat.id }) {
            chats.append(chat)
            saveChats(chats)
        }
    }
    
    func updateChat(_ chat: Chat) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index] = chat
            saveChats(chats)
        }
    }
    
    // MARK: - Messages
    
    func saveMessages(_ messages: [Message], for chatID: String) {
        self.messages[chatID] = messages.sorted { $0.timestamp < $1.timestamp }
        cacheMessages()
    }
    
    func addMessage(_ message: Message, to chatID: String) {
        if messages[chatID] == nil {
            messages[chatID] = []
        }
        messages[chatID]?.append(message)
        messages[chatID]?.sort { $0.timestamp < $1.timestamp }
        cacheMessages()
    }
    
    func getMessages(for chatID: String) -> [Message] {
        return messages[chatID] ?? []
    }
    
    // MARK: - Users
    
    func saveUser(_ user: User) {
        users[user.id] = user
        cacheUsers()
    }
    
    func getUser(id: String) -> User? {
        return users[id]
    }
    
    // MARK: - Caching
    
    private func cacheChats(_ chats: [Chat]) {
        if let data = try? JSONEncoder().encode(chats) {
            UserDefaults.standard.set(data, forKey: chatsKey)
        }
    }
    
    private func cacheMessages() {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: messagesKey)
        }
    }
    
    private func cacheUsers() {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }
    
    private func loadCachedData() {
        // Загрузить чаты
        if let data = UserDefaults.standard.data(forKey: chatsKey),
           let chats = try? JSONDecoder().decode([Chat].self, from: data) {
            self.chats = chats
        }
        
        // Загрузить сообщения
        if let data = UserDefaults.standard.data(forKey: messagesKey),
           let messages = try? JSONDecoder().decode([String: [Message]].self, from: data) {
            self.messages = messages
        }
        
        // Загрузить пользователей
        if let data = UserDefaults.standard.data(forKey: usersKey),
           let users = try? JSONDecoder().decode([String: User].self, from: data) {
            self.users = users
        }
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: chatsKey)
        UserDefaults.standard.removeObject(forKey: messagesKey)
        UserDefaults.standard.removeObject(forKey: usersKey)
        chats = []
        messages = [:]
        users = [:]
    }
}

