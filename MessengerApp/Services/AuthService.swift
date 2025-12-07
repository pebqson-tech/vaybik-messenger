//
//  AuthService.swift
//  MessengerApp
//
//  Сервис аутентификации
//

import Foundation
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let networkService = NetworkService.shared
    
    private init() {
        // Проверяем сохраненную сессию при запуске
        if let user = User.current, let _ = networkService.getAuthToken() {
            self.currentUser = user
            self.isAuthenticated = true
            // Загружаем актуальные данные пользователя
            Task {
                try? await loadCurrentUser()
            }
        }
    }
    
    func login(login: String, password: String) async throws {
        let response = try await networkService.login(login: login, password: password)
        
        // Сохраняем токен
        networkService.setAuthToken(response.token)
        
        await MainActor.run {
            self.currentUser = response.user
            self.isAuthenticated = true
            User.current = response.user
        }
    }
    
    func register(name: String, username: String?, email: String, password: String) async throws {
        let response = try await networkService.register(name: name, username: username, email: email, password: password)
        
        // Сохраняем токен
        networkService.setAuthToken(response.token)
        
        await MainActor.run {
            self.currentUser = response.user
            self.isAuthenticated = true
            User.current = response.user
        }
    }
    
    func loadCurrentUser() async throws {
        let user = try await networkService.getMe()
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
            User.current = user
        }
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        User.current = nil
        networkService.setAuthToken(nil)
    }
}

