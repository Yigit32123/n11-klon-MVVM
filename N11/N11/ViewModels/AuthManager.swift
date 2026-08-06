import SwiftUI
import Combine
import Foundation
import UIKit

// MARK: - State Managers
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    
    @Published var registeredUsers: [UserProfile] = [] {
        didSet { saveUsersToUserDefaults() }
    }
    
    @Published var showSuccessMessage = false
    @Published var loginError = false
    
    init() {
        loadUsersFromUserDefaults()
    }
    
    private func saveUsersToUserDefaults() {
        if let encodedData = try? JSONEncoder().encode(registeredUsers) {
            UserDefaults.standard.set(encodedData, forKey: "registeredUsers_Key")
        }
    }
    
    private func loadUsersFromUserDefaults() {
        if let savedData = UserDefaults.standard.data(forKey: "registeredUsers_Key"),
           let decodedUsers = try? JSONDecoder().decode([UserProfile].self, from: savedData) {
            self.registeredUsers = decodedUsers
        }
    }
    
    func register(user: UserProfile) {
        registeredUsers.append(user)
        withAnimation { showSuccessMessage = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { self.showSuccessMessage = false }
        }
    }
    
    func login(username: String, password: String) {
        if let user = registeredUsers.first(where: { $0.username == username && $0.password == password }) {
            currentUser = user
            isAuthenticated = true
            loginError = false
        } else {
            loginError = true
        }
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
    }
    
    func updateProfile(birthDate: Date, address: String, postalCode: String) {
        guard let index = registeredUsers.firstIndex(where: { $0.id == currentUser?.id }) else { return }
        registeredUsers[index].birthDate = birthDate
        registeredUsers[index].address = address
        registeredUsers[index].postalCode = postalCode
        currentUser = registeredUsers[index]
    }
}
//  AuthManager.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

