//
//  ChatListViewModel.swift
//  MessengerApp
//
//  ViewModel для списка чатов
//

import Foundation
import Combine

@MainActor
class ChatListViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService = NetworkService.shared
    private let storageService = StorageService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Подписываемся на обновления из хранилища
        storageService.$chats
            .assign(to: &$chats)
    }
    
    func loadChats() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedChats = try await networkService.getChats()
            storageService.saveChats(fetchedChats)
        } catch {
            errorMessage = "Не удалось загрузить чаты: \(error.localizedDescription)"
            // Используем кэшированные данные если есть
            chats = storageService.chats
        }
        
        isLoading = false
    }
    
    func createChat(with userID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let chat = try await networkService.createChat(with: userID)
            storageService.addChat(chat)
        } catch {
            errorMessage = "Не удалось создать чат: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshChats() async {
        await loadChats()
    }
}

