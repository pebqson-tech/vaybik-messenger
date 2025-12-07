//
//  ChatView.swift
//  MessengerApp
//
//  Экран чата
//

import SwiftUI

struct ChatView: View {
    let chatID: String
    @StateObject private var viewModel: ChatViewModel
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var storageService: StorageService
    @FocusState private var isTextFieldFocused: Bool
    
    init(chatID: String) {
        self.chatID = chatID
        self._viewModel = StateObject(wrappedValue: ChatViewModel(chatID: chatID))
    }
    
    var chat: Chat? {
        storageService.chats.first { $0.id == chatID }
    }
    
    var otherUser: User? {
        guard let chat = chat,
              let currentUserID = authService.currentUser?.id,
              let otherID = chat.otherParticipantID(currentUserID: currentUserID) else {
            return nil
        }
        return storageService.getUser(id: otherID)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Сообщения
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if viewModel.isLoading && viewModel.messages.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if viewModel.messages.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("Нет сообщений")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(message: message, isCurrentUser: message.senderID == authService.currentUser?.id)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Поле ввода
            HStack(spacing: 12) {
                Button(action: {
                    // TODO: Открыть выбор изображения
                }) {
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                TextField("Сообщение", text: $viewModel.newMessageText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...5)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }
                
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.newMessageText.isEmpty ? .gray : .blue)
                }
                .disabled(viewModel.newMessageText.isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(otherUser?.name ?? "Чат")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadMessages()
        }
    }
}

struct MessageBubbleView: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if let text = message.text {
                    Text(text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                        .foregroundColor(isCurrentUser ? .white : .primary)
                        .cornerRadius(18)
                }
                
                if let imageURL = message.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 250)
                            .cornerRadius(12)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 250, height: 200)
                            .overlay(ProgressView())
                    }
                }
                
                HStack(spacing: 4) {
                    Text(message.timeString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if isCurrentUser {
                        Image(systemName: statusIcon)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if !isCurrentUser {
                Spacer(minLength: 50)
            }
        }
    }
    
    private var statusIcon: String {
        switch message.status {
        case .sending:
            return "clock"
        case .sent:
            return "checkmark"
        case .delivered:
            return "checkmark"
        case .read:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.circle"
        }
    }
}

