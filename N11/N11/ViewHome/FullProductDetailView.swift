import SwiftUI
import Combine
import Foundation
import UIKit


// MARK: - Gelişmiş Detay Sayfası
struct FullProductDetailView: View {
    var baseProduct: Product? = nil
    let productDetail: ProductDetail
    @ObservedObject var cartManager: CartManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                TabView {
                    if let mainImage = baseProduct?.validImageUrl {
                        AsyncImage(url: mainImage) { image in
                            image.resizable().scaledToFit()
                        } placeholder: { ProgressView() }
                    } else {
                        ForEach(productDetail.validImageUrls, id: \.self) { url in
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFit()
                            } placeholder: { ProgressView() }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .frame(height: 350)
                .background(Color.white)
                
                VStack(alignment: .leading, spacing: 12) {
                    
                    Text(baseProduct?.title ?? productDetail.title)
                        .font(.title3)
                        .bold()
                    
                    if let rate = baseProduct?.rate ?? productDetail.rate {
                        HStack {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(rate) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 12))
                            }
                            Text("\(String(format: "%.1f", rate))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let seller = baseProduct?.sellerName ?? productDetail.sellerName {
                        Text("Satıcı: \(seller)")
                            .font(.subheadline)
                            .foregroundColor(.n11Accent) // TEMA RENGİ
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(String(format: "%.2f", baseProduct?.price ?? productDetail.price)) TL")
                                .strikethrough()
                                .foregroundColor(.gray)
                            
                            if let discountPrice = baseProduct?.instantDiscountPrice ?? productDetail.instantDiscountPrice {
                                Text("\(String(format: "%.2f", discountPrice)) TL")
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.green)
                            }
                        }
                        Spacer()
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ürün Özellikleri")
                            .font(.headline)
                        
                        Text(productDetail.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Spacer(minLength: 20)
                    
                    if let product = baseProduct {
                        let quantity = cartManager.getQuantity(for: product)
                        
                        HStack(spacing: 15) {
                            if quantity > 0 {
                                HStack(spacing: 20) {
                                    Button(action: {
                                        cartManager.removeFromCart(product: product)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.red)
                                    }
                                    
                                    Text("\(quantity)")
                                        .font(.title2)
                                        .bold()
                                        .frame(minWidth: 30)
                                    
                                    Button(action: {
                                        cartManager.addToCart(product: product)
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(.trailing, 10)
                            }
                            
                            Button(action: {
                                if quantity == 0 {
                                    cartManager.addToCart(product: product)
                                }
                            }) {
                                Text(quantity == 0 ? "Sepete Ekle" : "Sepete Eklendi")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(quantity == 0 ? Color.green : Color.gray)
                                    .cornerRadius(10)
                            }
                            .disabled(quantity > 0)
                        }
                    } else {
                        Text("Bu, özel indirimli bir kampanya ürünüdür. Lütfen sepete eklemek için detay sayfasına gitmek yerine sepet üzerinden doğrudan işlem yapınız.")
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
  }

#Preview {
    ContentView()
}

//  FullProductDetailView.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

