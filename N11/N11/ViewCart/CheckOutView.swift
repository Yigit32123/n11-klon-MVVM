import SwiftUI
import Combine
import Foundation
import UIKit

// MARK: - CheckoutView (Sipariş ve Ödeme Ekranı)
struct CheckoutView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var cartManager: CartManager
    @ObservedObject var orderManager: OrderManager
    @Binding var currentTab: AppTab
    
    @StateObject private var couponManager = CouponManager()
    
    @State private var name = ""
    @State private var address = ""
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var isProcessing = false
    
    @State private var couponCode = ""
    @State private var appliedCoupon: DiscountCoupon? = nil
    @State private var couponMessage: String? = nil
    @State private var couponMessageIsError = false
    
    // MARK: Tutar Hesaplamaları
    
    private var subtotal: Double {
        cartManager.totalPrice()
    }
    
    private var discountAmount: Double {
        guard let coupon = appliedCoupon, let value = DiscountCodeSystem.parse(coupon.code) else { return 0 }
        switch value {
        case .amount(let tl):
            return min(Double(tl), subtotal) // İndirim sepet tutarını geçmesin
        case .percent(let p):
            return subtotal * (Double(p) / 100)
        }
    }
    
    private var finalTotal: Double {
        max(subtotal - discountAmount, 0)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Teslimat Bilgileri")) {
                    TextField("Ad Soyad", text: $name)
                    TextField("Açık Adres", text: $address)
                }
                
                Section(header: Text("Ödeme Bilgileri (Sanal Kart)")) {
                    TextField("Kart Numarası", text: $cardNumber)
                        .keyboardType(.numberPad)
                    HStack {
                        TextField("AA/YY", text: $expiryDate)
                        TextField("CVV", text: $cvv)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section(header: Text("İndirim Kuponu")) {
                    HStack {
                        TextField("Kupon kodunu buraya yapıştırın", text: $couponCode)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .onChange(of: couponCode) { newValue in
                                tryApplyCoupon(newValue)
                            }
                        
                        if appliedCoupon != nil {
                            Button(action: removeCoupon) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    if let message = couponMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(couponMessageIsError ? .red : .green)
                    }
                }
                
                Section(header: Text("Sipariş Özeti")) {
                    HStack {
                        Text("Ara Toplam:")
                        Spacer()
                        Text("\(String(format: "%.2f", subtotal)) TL")
                            .foregroundColor(.secondary)
                    }
                    
                    if appliedCoupon != nil {
                        HStack {
                            Text("İndirim (\(appliedCoupon?.code.uppercased() ?? "")):")
                            Spacer()
                            Text("-\(String(format: "%.2f", discountAmount)) TL")
                                .foregroundColor(.n11Accent) // TEMA RENGİ
                        }
                    }
                    
                    HStack {
                        Text("Ödenecek Tutar:")
                            .font(.headline)
                        Spacer()
                        Text("\(String(format: "%.2f", finalTotal)) TL")
                            .bold()
                            .foregroundColor(.green)
                    }
                }
                
                Section {
                    Button(action: processOrder) {
                        if isProcessing {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Siparişi Onayla")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .listRowBackground(Color.green)
                    .disabled(address.isEmpty || cardNumber.isEmpty || isProcessing)
                }
            }
            .navigationTitle("Ödeme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
            .onAppear {
                if let user = authManager.currentUser {
                    name = "\(user.name) \(user.surname)"
                    address = user.address
                }
            }
        }
    }
    
    // MARK: Kupon Doğrulama
    
    private func tryApplyCoupon(_ rawCode: String) {
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard code.count == 8 else {
            appliedCoupon = nil
            couponMessage = nil
            return
        }
        
        guard let coupon = couponManager.coupons.first(where: { $0.code == code }) else {
            appliedCoupon = nil
            couponMessage = "Bu kod geçerli değil."
            couponMessageIsError = true
            return
        }
        
        guard !coupon.isUsed else {
            appliedCoupon = nil
            couponMessage = "Bu kod daha önce kullanılmış."
            couponMessageIsError = true
            return
        }
        
        guard let value = DiscountCodeSystem.parse(coupon.code) else {
            appliedCoupon = nil
            couponMessage = "Bu kod okunamadı."
            couponMessageIsError = true
            return
        }
        
        appliedCoupon = coupon
        couponMessage = "\(value.displayText) indirim uygulandı."
        couponMessageIsError = false
    }
    
    private func removeCoupon() {
        couponCode = ""
        appliedCoupon = nil
        couponMessage = nil
    }
    
    private func processOrder() {
        isProcessing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            orderManager.createOrder(
                items: cartManager.cartItems,
                totalAmount: finalTotal,
                originalAmount: appliedCoupon != nil ? subtotal : nil,
                address: address,
                appliedCouponCode: appliedCoupon?.code,
                discountAmount: appliedCoupon != nil ? discountAmount : nil
            )
            
            if let coupon = appliedCoupon {
                couponManager.markUsed(code: coupon.code)
            }
            
            cartManager.clearCart()
            isProcessing = false
            dismiss()
            currentTab = .orders
        }
    }
}
//  CheckOutView.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//
