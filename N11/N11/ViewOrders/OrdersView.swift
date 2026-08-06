import SwiftUI
import Combine
import Foundation
import UIKit


// MARK: - OrdersView (Siparişler)
struct OrdersView: View {
    @ObservedObject var orderManager: OrderManager
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if orderManager.orders.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Henüz siparişiniz bulunmuyor.")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(orderManager.orders) { order in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Sipariş No: \(order.orderNumber)")
                                        .font(.subheadline)
                                        .bold()
                                    Spacer()
                                    Text(order.date, formatter: dateFormatter)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Text("\(order.items.count) ürün")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                
                                Divider()
                                
                                HStack {
                                    Text(order.status.rawValue)
                                        .font(.caption)
                                        .bold()
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(statusColor(for: order.status).opacity(0.1))
                                        .foregroundColor(statusColor(for: order.status))
                                        .cornerRadius(6)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        if let original = order.originalAmount, let code = order.appliedCouponCode {
                                            Text("\(String(format: "%.2f", original)) TL")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .strikethrough()
                                            Text("\(String(format: "%.2f", order.totalAmount)) TL")
                                                .font(.headline)
                                                .foregroundColor(.green)
                                            Text("Kupon: \(code.uppercased())")
                                                .font(.caption2)
                                                .foregroundColor(.n11Accent) // TEMA RENGİ
                                        } else {
                                            Text("\(String(format: "%.2f", order.totalAmount)) TL")
                                                .font(.headline)
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Siparişlerim")
        }
    }
    
    private func statusColor(for status: OrderStatus) -> Color {
        switch status {
        case .received: return .orange
        case .preparing: return .blue
        case .shipped: return .purple
        case .delivered: return .green
        }
    }
}
//  OrdersView.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

