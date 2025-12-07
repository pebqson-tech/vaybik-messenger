//
//  MessengerApp.swift
//  MessengerApp
//
//  Created on 2024
//

import SwiftUI

@main
struct MessengerApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var storageService = StorageService.shared
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                MainTabView()
                    .environmentObject(authService)
                    .environmentObject(storageService)
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatListView()
                .tabItem {
                    Label("Чаты", systemImage: "message.fill")
                }
                .tag(0)
            
            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.fill")
                }
                .tag(1)
        }
    }
}

