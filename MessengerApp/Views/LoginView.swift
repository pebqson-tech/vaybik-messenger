//
//  LoginView.swift
//  MessengerApp
//
//  Экран входа и регистрации
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var login = "" // Email или username для входа
    @State private var password = ""
    @State private var name = ""
    @State private var username = "" // Username для регистрации (необязательно)
    @State private var email = "" // Email для регистрации
    @State private var isRegisterMode = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Логотип или заголовок
                VStack(spacing: 10) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Вайбик")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Форма
                VStack(spacing: 16) {
                    if isRegisterMode {
                        TextField("Имя", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                        
                        TextField("Имя пользователя (необязательно)", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    } else {
                        TextField("Email или Username", text: $login)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.default)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    SecureField("Пароль", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    Button(action: handleSubmit) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isRegisterMode ? "Зарегистрироваться" : "Войти")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading || password.isEmpty || 
                              (isRegisterMode ? (name.isEmpty || email.isEmpty) : login.isEmpty))
                    
                    Button(action: {
                        isRegisterMode.toggle()
                        errorMessage = nil
                    }) {
                        Text(isRegisterMode ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func handleSubmit() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if isRegisterMode {
                    let usernameValue = username.isEmpty ? nil : username
                    try await authService.register(name: name, username: usernameValue, email: email, password: password)
                } else {
                    try await authService.login(login: login, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

