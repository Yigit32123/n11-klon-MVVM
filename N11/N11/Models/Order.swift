import SwiftUI
import Combine
import Foundation
import UIKit


enum OrderStatus: String, Codable, CaseIterable {
    case received = "Sipariş Alındı"
    case preparing = "Hazırlanıyor"
    case shipped = "Kargoya Verildi"
    case delivered = "Teslim Edildi"
}
struct Order: Identifiable, Codable {
    var id = UUID()
    let orderNumber: String
    let date: Date
    let items: [CartItem]
    let totalAmount: Double
    let address: String
    var status: OrderStatus
    var originalAmount: Double? = nil
    var appliedCouponCode: String? = nil
    var discountAmount: Double? = nil
}
//  Order.swift
//  ETdeneme
//
//  Created by yigit.korkmaz on 6.08.2026.
//

