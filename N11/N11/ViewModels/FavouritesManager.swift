import SwiftUI
import Combine
import Foundation
import UIKit

// MARK: - Favorites Manager
class FavoritesManager: ObservableObject {
    @Published var favoriteProducts: [Product] = [] {
        didSet { saveFavorites() }
    }
    
    var currentUserId: String = "" {
        didSet {
            if !currentUserId.isEmpty {
                loadFavorites()
            }
        }
    }
    
    func toggleFavorite(product: Product) {
        if let index = favoriteProducts.firstIndex(where: { $0.id == product.id }) {
            favoriteProducts.remove(at: index)
        } else {
            favoriteProducts.append(product)
        }
    }
    
    func isFavorite(product: Product) -> Bool {
        return favoriteProducts.contains(where: { $0.id == product.id })
    }
    
    private func saveFavorites() {
        guard !currentUserId.isEmpty else { return }
        if let encodedData = try? JSONEncoder().encode(favoriteProducts) {
            UserDefaults.standard.set(encodedData, forKey: "saved_favorites_\(currentUserId)")
        }
    }
    
    private func loadFavorites() {
        guard !currentUserId.isEmpty else { return }
        if let savedData = UserDefaults.standard.data(forKey: "saved_favorites_\(currentUserId)"),
           let decoded = try? JSONDecoder().decode([Product].self, from: savedData) {
            self.favoriteProducts = decoded
        } else {
            self.favoriteProducts = []
        }
    }
}
//  FavouritesManager.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

