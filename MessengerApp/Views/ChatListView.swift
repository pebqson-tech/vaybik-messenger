//
//  ChatListView.swift
//  MessengerApp
//
//  Список чатов
//

import SwiftUI

struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var searchText = ""
    @State private var showingNewChat = false
    
    var filteredChats: [Chat] {
        if searchText.isEmpty {
            return viewModel.chats.sorted { $0.lastMessageDate > $1.lastMessageDate }
        }
        return viewModel.chats.filter { chat in
            // TODO: Добавить поиск по имени собеседника
            chat.lastMessage?.text?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading && viewModel.chats.isEmpty {
                    ProgressView("Загрузка чатов...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredChats.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Нет чатов")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Начните новый чат, нажав кнопку +")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredChats) { chat in
                        NavigationLink(destination: ChatView(chatID: chat.id)) {
                            ChatRowView(chat: chat)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Вайбик")
            .searchable(text: $searchText, prompt: "Поиск чатов")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewChat = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewChat) {
                NewChatView()
            }
            .refreshable {
                await viewModel.refreshChats()
            }
            .task {
                await viewModel.loadChats()
            }
        }
    }
}

struct ChatRowView: View {
    let chat: Chat
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var storageService: StorageService
    
    var otherUser: User? {
        guard let currentUserID = authService.currentUser?.id,
              let otherID = chat.otherParticipantID(currentUserID: currentUserID) else {
            return nil
        }
        return storageService.getUser(id: otherID)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Аватар
            AsyncImage(url: URL(string: otherUser?.avatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text((otherUser?.name.prefix(1) ?? "?").uppercased())
                            .font(.headline)
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(otherUser?.name ?? "Неизвестный")
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(chat.lastMessageDate.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if let lastMessage = chat.lastMessage {
                        Text(lastMessage.text ?? "Изображение")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("Нет сообщений")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    Spacer()
                    
                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// Расширение для форматирования времени
extension Date {
    var timeAgo: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        if let day = components.day, day > 0 {
            if day == 1 {
                return "Вчера"
            } else if day < 7 {
                return "\(day)д"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM"
                return formatter.string(from: self)
            }
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)ч"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)м"
        } else {
            return "Сейчас"
        }
    }
}

struct NewChatView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ChatListViewModel()
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isSearching {
                    ProgressView("Поиск...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Пользователи не найдены")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(searchResults) { user in
                        Button(action: {
                            Task {
                                await viewModel.createChat(with: user.id)
                                dismiss()
                            }
                        }) {
                            HStack {
                                AsyncImage(url: URL(string: user.avatarURL ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Text(user.name.prefix(1).uppercased())
                                                .font(.headline)
                                                .foregroundColor(.gray)
                                        )
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                
                                Text(user.name)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Новый чат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Поиск пользователей")
            .onChange(of: searchText) { newValue in
                if !newValue.isEmpty {
                    searchUsers(query: newValue)
                } else {
                    searchResults = []
                }
            }
        }
    }
    
    private func searchUsers(query: String) {
        isSearching = true
        Task {
            do {
                let results = try await NetworkService.shared.searchUsers(query: query)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                }
            }
        }
    }
}

