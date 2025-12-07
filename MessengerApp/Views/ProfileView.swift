//
//  ProfileView.swift
//  MessengerApp
//
//  Экран профиля пользователя
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 16) {
                        AsyncImage(url: URL(string: authService.currentUser?.avatarURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .overlay(
                                    Text((authService.currentUser?.name.prefix(1) ?? "?").uppercased())
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                )
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.currentUser?.name ?? "Пользователь")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if let email = authService.currentUser?.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let status = authService.currentUser?.status {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(statusColor(status))
                                        .frame(width: 8, height: 8)
                                    Text(statusText(status))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Настройки") {
                    Button(action: {
                        // TODO: Редактировать профиль
                    }) {
                        Label("Редактировать профиль", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        // TODO: Настройки уведомлений
                    }) {
                        Label("Уведомления", systemImage: "bell")
                    }
                    
                    Button(action: {
                        // TODO: Приватность
                    }) {
                        Label("Приватность", systemImage: "lock")
                    }
                }
                
                Section("О приложении") {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        // TODO: Политика конфиденциальности
                    }) {
                        Text("Политика конфиденциальности")
                    }
                    
                    Button(action: {
                        // TODO: Условия использования
                    }) {
                        Text("Условия использования")
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Выйти")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Профиль")
            .alert("Выйти из аккаунта?", isPresented: $showingLogoutAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Выйти", role: .destructive) {
                    authService.logout()
                }
            } message: {
                Text("Вы уверены, что хотите выйти?")
            }
        }
    }
    
    private func statusColor(_ status: User.UserStatus) -> Color {
        switch status {
        case .online:
            return .green
        case .offline:
            return .gray
        case .away:
            return .orange
        }
    }
    
    private func statusText(_ status: User.UserStatus) -> String {
        switch status {
        case .online:
            return "В сети"
        case .offline:
            return "Не в сети"
        case .away:
            return "Отошёл"
        }
    }
}

