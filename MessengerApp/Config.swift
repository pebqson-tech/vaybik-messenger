//
//  Config.swift
//  MessengerApp
//
//  Конфигурация приложения
//

import Foundation

struct AppConfig {
    // Замените на IP адрес вашего сервера
    // Для локальной разработки: http://192.168.x.x:3001
    // Для тестирования на симуляторе: http://localhost:3001
    // Для тестирования на реальном устройстве: http://ВАШ_IP:3001
    static let baseURL = "http://192.168.1.100:3001"
    
    static var apiURL: String {
        return "\(baseURL)/api"
    }
    
    // Использовать mock данные (для тестирования без сервера)
    static let useMockData = false
}

