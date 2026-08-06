import SwiftUI
import Combine
import Foundation
import UIKit

// MARK: - Order Manager
class OrderManager: ObservableObject {
    @Published var orders: [Order] = [] {
        didSet { saveOrders() }
    }
    
    var currentUserId: String = "" {
        didSet {
            if !currentUserId.isEmpty {
                loadOrders()
            }
        }
    }
    
    func createOrder(items: [CartItem], totalAmount: Double, originalAmount: Double? = nil, address: String, appliedCouponCode: String? = nil, discountAmount: Double? = nil) {
        let newOrder = Order(
            orderNumber: String(Int.random(in: 10000000...99999999)),
            date: Date(),
            items: items,
            totalAmount: totalAmount,
            address: address,
            status: .preparing,
            originalAmount: originalAmount,
            appliedCouponCode: appliedCouponCode,
            discountAmount: discountAmount
        )
        orders.insert(newOrder, at: 0)
    }
    
    private func saveOrders() {
        guard !currentUserId.isEmpty else { return }
        if let encodedData = try? JSONEncoder().encode(orders) {
            UserDefaults.standard.set(encodedData, forKey: "saved_orders_\(currentUserId)")
        }
    }
    
    private func loadOrders() {
        guard !currentUserId.isEmpty else { return }
        if let savedData = UserDefaults.standard.data(forKey: "saved_orders_\(currentUserId)"),
           let decoded = try? JSONDecoder().decode([Order].self, from: savedData) {
            self.orders = decoded
        } else {
            self.orders = []
        }
    }
}

//  OrderManager.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

