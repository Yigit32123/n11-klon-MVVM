import SwiftUI
import Combine
import Foundation
import UIKit


// MARK: - Sepet Görünümü (CartView)
struct CartView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var cartManager: CartManager
    @ObservedObject var orderManager: OrderManager
    @Binding var currentTab: AppTab
    
    @State private var showCheckout = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if cartManager.cartItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Sepetiniz şu an boş.")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(cartManager.cartItems) { item in
                                HStack(spacing: 15) {
                                    AsyncImage(url: item.product.validImageUrl) { image in
                                        image.resizable().scaledToFit()
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                    }
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(item.product.title)
                                            .font(.subheadline)
                                            .lineLimit(2)
                                        
                                        let price = item.product.instantDiscountPrice ?? item.product.price
                                        Text("\(String(format: "%.2f", price)) TL")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(spacing: 8) {
                                        Button(action: { cartManager.addToCart(product: item.product) }) {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.title3)
                                        }
                                        Text("\(item.quantity)")
                                            .font(.headline)
                                        Button(action: { cartManager.removeFromCart(product: item.product) }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.title3)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
                            }
                        }
                        .padding()
                        .padding(.bottom, 120)
                    }
                    
                    VStack {
                        HStack {
                            Text("Toplam Tutar:")
                                .font(.headline)
                            Spacer()
                            Text("\(String(format: "%.2f", cartManager.totalPrice())) TL")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        Button(action: {
                            showCheckout = true
                        }) {
                            Text("Ödeme Yap")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.n11Accent) // TEMA RENGİ
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                    .background(Color.white)
                    .shadow(radius: 5)
                }
            }
            .navigationTitle("Sepetim")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCheckout) {
                CheckoutView(cartManager: cartManager, orderManager: orderManager, currentTab: $currentTab)
                    .environmentObject(authManager)
            }
        }
    }
}
//  CartView.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

