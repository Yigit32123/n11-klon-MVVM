import SwiftUI
import Combine
import Foundation
import UIKit


// MARK: - Main App View
struct MainAppView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = StoreViewModel()
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var cartManager = CartManager()
    @StateObject private var orderManager = OrderManager()
    
    @State private var currentTab: AppTab = .home
    @State private var isMenuOpen: Bool = false
    @State private var showWheelSheet: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                switch currentTab {
                case .home:
                    HomeView(viewModel: viewModel, favoritesManager: favoritesManager, cartManager: cartManager)
                case .favorites:
                    FavoritesView(favoritesManager: favoritesManager, cartManager: cartManager)
                case .cart:
                    CartView(cartManager: cartManager, orderManager: orderManager, currentTab: $currentTab)
                case .orders:
                    OrdersView(orderManager: orderManager)
                case .account:
                    AccountView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if isMenuOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            isMenuOpen = false
                        }
                    }
            }
            
            if isMenuOpen {
                VStack(alignment: .leading, spacing: 20) {
                    
                    HStack(spacing: 15) {
                        Image("n11Logo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.n11Accent.opacity(0.4), lineWidth: 1)) // TEMA RENGİ
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.name ?? "Kullanıcı")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.n11Accent) // TEMA RENGİ
                            Text("@\(authManager.currentUser?.username ?? "")")
                                .font(.caption)
                                .foregroundColor(.n11Accent) // TEMA RENGİ
                        }
                    }
                    .padding(.bottom, 10)
                    
                    Divider()
                        .background(Color.n11Accent.opacity(0.4)) // TEMA RENGİ
                    
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        Button(action: {
                            currentTab = tab
                            withAnimation(.easeInOut) {
                                isMenuOpen = false
                            }
                        }) {
                            HStack(spacing: 15) {
                                Image(systemName: tab.iconName)
                                    .frame(width: 24)
                                Text(tab.rawValue)
                                    .font(.headline)
                            }
                            .foregroundColor(.n11Accent) // TEMA RENGİ
                            .padding(.vertical, 8)
                        }
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut) {
                            isMenuOpen = false
                        }
                        // Menü kapanış animasyonu bittikten sonra çarkı aç
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            showWheelSheet = true
                        }
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "gift.fill")
                                .frame(width: 24)
                            Text("Bana Ne Var")
                                .font(.headline)
                        }
                        .foregroundColor(.n11Accent) // TEMA RENGİ
                        .padding(.vertical, 8)
                    }
                    
                    Spacer()
                    Divider()
                        .background(Color.n11Accent.opacity(0.4)) // TEMA RENGİ
                    
                    Button(action: {
                        authManager.logout()
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .frame(width: 24)
                            Text("Çıkış Yap")
                                .font(.headline)
                        }
                        .foregroundColor(.n11Accent) // TEMA RENGİ
                        .padding(.vertical, 8)
                    }
                }
                .padding(25)
                .frame(width: 280, alignment: .leading)
                .background(Color.black)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(.leading, 20)
                .padding(.bottom, 120)
                .transition(.move(edge: .leading).combined(with: .opacity))
                .zIndex(1)
            }
            
            Button(action: {
                withAnimation(.easeInOut) {
                    isMenuOpen.toggle()
                }
            }) {
                Circle()
                    .fill(Color.black)
                    .frame(width: 55, height: 55)
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                    .overlay(
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.n11Accent) // TEMA RENGİ
                            .font(.system(size: 22, weight: .bold))
                    )
            }
            .padding(.leading, 20)
            .padding(.bottom, 120)
            .zIndex(2)
        }
        .onAppear {
            if let username = authManager.currentUser?.username {
                favoritesManager.currentUserId = username
                cartManager.currentUserId = username
                orderManager.currentUserId = username
            }
        }
        .sheet(isPresented: $showWheelSheet) {
            SpinWheelView()
        }
    }
}
//  MainAppView.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

