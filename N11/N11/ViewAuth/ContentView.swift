import SwiftUI
import Combine
import Foundation
import UIKit


// MARK: - Root View
struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainAppView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
//  ContentView.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

