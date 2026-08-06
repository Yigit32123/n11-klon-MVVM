import SwiftUI
import Combine
import Foundation
import UIKit

// MARK: - Cart Manager
class CartManager: ObservableObject {
    @Published var cartItems: [CartItem] = [] {
        didSet { saveCart() }
    }
    
    var currentUserId: String = "" {
        didSet {
            if !currentUserId.isEmpty {
                loadCart()
            }
        }
    }
    
    func addToCart(product: Product) {
        if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            cartItems[index].quantity += 1
        } else {
            cartItems.append(CartItem(product: product, quantity: 1))
        }
    }
    
    func removeFromCart(product: Product) {
        if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            if cartItems[index].quantity > 1 {
                cartItems[index].quantity -= 1
            } else {
                cartItems.remove(at: index)
            }
        }
    }
    
    func getQuantity(for product: Product) -> Int {
        return cartItems.first(where: { $0.product.id == product.id })?.quantity ?? 0
    }
    
    func totalPrice() -> Double {
        return cartItems.reduce(0) { total, item in
            let price = item.product.instantDiscountPrice ?? item.product.price
            return total + (price * Double(item.quantity))
        }
    }
    
    func clearCart() {
        cartItems.removeAll()
    }
    
    private func saveCart() {
        guard !currentUserId.isEmpty else { return }
        if let encodedData = try? JSONEncoder().encode(cartItems) {
            UserDefaults.standard.set(encodedData, forKey: "saved_cart_\(currentUserId)")
        }
    }
    
    private func loadCart() {
        guard !currentUserId.isEmpty else { return }
        if let savedData = UserDefaults.standard.data(forKey: "saved_cart_\(currentUserId)"),
           let decoded = try? JSONDecoder().decode([CartItem].self, from: savedData) {
            self.cartItems = decoded
        } else {
            self.cartItems = []
        }
    }
}
//  Cart Manager.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

