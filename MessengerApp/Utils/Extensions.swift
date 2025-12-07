//
//  Extensions.swift
//  MessengerApp
//
//  Расширения и утилиты
//

import Foundation
import SwiftUI

// Расширение для Color
extension Color {
    static let messageBubbleBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let messageBubbleGray = Color(.systemGray5)
}

// Расширение для View
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

