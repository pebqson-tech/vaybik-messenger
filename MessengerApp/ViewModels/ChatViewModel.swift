//
//  ChatViewModel.swift
//  MessengerApp
//
//  ViewModel для экрана чата
//

import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var newMessageText = ""
    
    let chatID: String
    private let networkService = NetworkService.shared
    private let storageService = StorageService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(chatID: String) {
        self.chatID = chatID
        
        // Подписываемся на обновления сообщений из хранилища
        storageService.$messages
            .map { $0[chatID] ?? [] }
            .assign(to: &$messages)
    }
    
    func loadMessages() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedMessages = try await networkService.getMessages(chatID: chatID)
            storageService.saveMessages(fetchedMessages, for: chatID)
        } catch {
            errorMessage = "Не удалось загрузить сообщения: \(error.localizedDescription)"
            // Используем кэшированные данные если есть
            messages = storageService.getMessages(for: chatID)
        }
        
        isLoading = false
    }
    
    func sendMessage() async {
        guard !newMessageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let text = newMessageText
        newMessageText = ""
        
        // Создаем локальное сообщение для мгновенного отображения
        let localMessage = Message(
            chatID: chatID,
            senderID: AuthService.shared.currentUser?.id ?? "",
            text: text,
            status: .sending
        )
        
        storageService.addMessage(localMessage, to: chatID)
        
        do {
            let sentMessage = try await networkService.sendMessage(chatID: chatID, text: text)
            // Заменяем локальное сообщение на отправленное
            if let index = messages.firstIndex(where: { $0.id == localMessage.id }) {
                var updatedMessages = messages
                updatedMessages[index] = sentMessage
                storageService.saveMessages(updatedMessages, for: chatID)
            }
        } catch {
            errorMessage = "Не удалось отправить сообщение: \(error.localizedDescription)"
            // Обновляем статус сообщения на failed
            if let index = messages.firstIndex(where: { $0.id == localMessage.id }) {
                var updatedMessages = messages
                updatedMessages[index].status = .failed
                storageService.saveMessages(updatedMessages, for: chatID)
            }
        }
    }
    
    func loadMoreMessages() async {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        
        do {
            let fetchedMessages = try await networkService.getMessages(
                chatID: chatID,
                limit: 50,
                offset: messages.count
            )
            
            var allMessages = messages + fetchedMessages
            allMessages.sort { $0.timestamp < $1.timestamp }
            storageService.saveMessages(allMessages, for: chatID)
        } catch {
            errorMessage = "Не удалось загрузить сообщения: \(error.localizedDescription)"
        }
        
        isLoadingMore = false
    }
}

