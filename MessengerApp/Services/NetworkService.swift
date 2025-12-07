//
//  NetworkService.swift
//  MessengerApp
//
//  Сетевой слой для API запросов
//

import Foundation

class NetworkService {
    static let shared = NetworkService()
    
    // Включите мок-режим для тестирования без бэкенда
    var useMockData: Bool = AppConfig.useMockData
    
    private let baseURL = AppConfig.apiURL
    private let session: URLSession
    private let mockService = MockService.shared
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Auth
    
    func login(login: String, password: String) async throws -> AuthResponse {
        if useMockData {
            try await Task.sleep(nanoseconds: 500_000_000)
            let user = User(
                id: UUID().uuidString,
                name: login.components(separatedBy: "@").first ?? "User",
                email: login.contains("@") ? login : nil,
                status: .online
            )
            return AuthResponse(user: user, token: "mock-token")
        }
        
        let endpoint = "/auth/login"
        let body: [String: Any] = [
            "login": login, // Может быть email или username
            "password": password
        ]
        return try await request(endpoint: endpoint, method: "POST", body: body)
    }
    
    func register(name: String, username: String?, email: String, password: String) async throws -> AuthResponse {
        if useMockData {
            try await Task.sleep(nanoseconds: 500_000_000)
            let user = User(
                id: UUID().uuidString,
                name: name,
                email: email,
                status: .online
            )
            return AuthResponse(user: user, token: "mock-token")
        }
        
        let endpoint = "/auth/register"
        var body: [String: Any] = [
            "name": name,
            "email": email,
            "password": password
        ]
        if let username = username, !username.isEmpty {
            body["username"] = username
        }
        return try await request(endpoint: endpoint, method: "POST", body: body)
    }
    
    func getMe() async throws -> User {
        if useMockData {
            try await Task.sleep(nanoseconds: 200_000_000)
            return mockService.getMockUsers().first ?? User(name: "User", status: .online)
        }
        
        let endpoint = "/auth/me"
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    // MARK: - Chats
    
    func getChats() async throws -> [Chat] {
        if useMockData {
            // Имитируем задержку сети
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 секунды
            return mockService.getMockChats()
        }
        let endpoint = "/chats"
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    func getChat(id: String) async throws -> Chat {
        let endpoint = "/chats/\(id)"
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    func createChat(with userID: String) async throws -> Chat {
        if useMockData {
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 секунды
            return mockService.createMockChat(with: userID)
        }
        let endpoint = "/chats"
        let body: [String: Any] = ["participantID": userID]
        return try await request(endpoint: endpoint, method: "POST", body: body)
    }
    
    // MARK: - Messages
    
    func getMessages(chatID: String, limit: Int = 50, offset: Int = 0) async throws -> [Message] {
        if useMockData {
            try await Task.sleep(nanoseconds: 400_000_000) // 0.4 секунды
            var messages = mockService.getMockMessages(for: chatID)
            // Применяем пагинацию
            if offset > 0 {
                messages = Array(messages.dropFirst(offset))
            }
            if messages.count > limit {
                messages = Array(messages.prefix(limit))
            }
            return messages
        }
        let endpoint = "/chats/\(chatID)/messages?limit=\(limit)&offset=\(offset)"
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    func sendMessage(chatID: String, text: String?, imageURL: String? = nil, fileURL: String? = nil) async throws -> Message {
        if useMockData {
            // Имитируем задержку отправки
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 секунды
            
            let currentUserID = AuthService.shared.currentUser?.id ?? "current_user"
            let message = Message(
                id: UUID().uuidString,
                chatID: chatID,
                senderID: currentUserID,
                text: text,
                imageURL: imageURL,
                fileURL: fileURL,
                timestamp: Date(),
                isRead: false,
                status: .sent
            )
            
            mockService.addMockMessage(message, to: chatID)
            return message
        }
        let endpoint = "/chats/\(chatID)/messages"
        var body: [String: Any] = [:]
        if let text = text {
            body["text"] = text
        }
        if let imageURL = imageURL {
            body["imageURL"] = imageURL
        }
        if let fileURL = fileURL {
            body["fileURL"] = fileURL
        }
        return try await request(endpoint: endpoint, method: "POST", body: body)
    }
    
    func sendImage(chatID: String, imageData: Data) async throws -> Message {
        let endpoint = "/chats/\(chatID)/messages/image"
        // TODO: Реализовать multipart/form-data загрузку
        return try await request(endpoint: endpoint, method: "POST", body: ["image": imageData.base64EncodedString()])
    }
    
    // MARK: - Users
    
    func searchUsers(query: String) async throws -> [User] {
        if useMockData {
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 секунды
            return mockService.searchMockUsers(query: query)
        }
        let endpoint = "/users/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    func getUser(id: String) async throws -> User {
        if useMockData {
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 секунды
            if let user = mockService.getMockUsers().first(where: { $0.id == id }) {
                return user
            }
            throw NetworkError.noData
        }
        let endpoint = "/users/\(id)"
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    // MARK: - Generic Request
    
    private func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: [String: Any]? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Добавить токен авторизации если есть
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Попытаемся прочитать сообщение об ошибке
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? String {
                throw NetworkError.apiError(errorMessage)
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        // Backend использует timestamp в миллисекундах
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let timestamp = try container.decode(Int64.self)
            return Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
        }
        return try decoder.decode(T.self, from: data)
    }
    
    private func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    func setAuthToken(_ token: String?) {
        if let token = token {
            UserDefaults.standard.set(token, forKey: "authToken")
        } else {
            UserDefaults.standard.removeObject(forKey: "authToken")
        }
    }
    
    func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    case noData
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .httpError(let code):
            return "Ошибка HTTP: \(code)"
        case .decodingError:
            return "Ошибка декодирования данных"
        case .noData:
            return "Нет данных"
        case .apiError(let message):
            return message
        }
    }
}

