import SwiftUI
import Combine
import Foundation
import UIKit


// MARK: - Ürün Kartı
struct ProductCard: View {
    let product: Product
    @ObservedObject var favoritesManager: FavoritesManager
    
    // Üründe yorum sayısı/kargo bilgisi API'den gelmediği için id'den sabit (kart her yeniden çizildiğinde değişmeyen) türetiyoruz
    private var reviewCount: Int {
        100 + (product.id % 900)
    }
    
    private var hasFreeShipping: Bool {
        product.id % 3 == 0
    }
    
    private var isSuperPrice: Bool {
        (product.rate ?? 0) >= 4.5
    }
    
    private var discountPercent: Int? {
        guard let discountPrice = product.instantDiscountPrice, product.price > 0, discountPrice < product.price else { return nil }
        return Int(((product.price - discountPrice) / product.price) * 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: product.validImageUrl) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Color.gray.opacity(0.1)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                Button(action: {
                    favoritesManager.toggleFavorite(product: product)
                }) {
                    Image(systemName: favoritesManager.isFavorite(product: product) ? "heart.fill" : "heart")
                        .foregroundColor(favoritesManager.isFavorite(product: product) ? .n11Accent : .black) // TEMA RENGİ
                        .font(.system(size: 20))
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 3)
                }
                .padding(.top, 8)
                .padding(.trailing, 2)
            }
            
            if isSuperPrice || hasFreeShipping {
                HStack(spacing: 4) {
                    if isSuperPrice {
                        Text("Süper Fiyat")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black)
                            .cornerRadius(4)
                    }
                    if hasFreeShipping {
                        HStack(spacing: 2) {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 8))
                            Text("Ücretsiz Kargo")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.n11Accent) // TEMA RENGİ
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.n11Accent.opacity(0.12)) // TEMA RENGİ
                        .cornerRadius(4)
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Text(product.title)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(minHeight: 40, alignment: .topLeading)
                .padding(.horizontal, 8)
            
            if let rate = product.rate, rate > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text(String(format: "%.1f", rate))
                        .font(.system(size: 11, weight: .semibold))
                    Text("(\(reviewCount))")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if let discountPrice = product.instantDiscountPrice, discountPrice < product.price {
                    HStack(spacing: 6) {
                        Text("\(String(format: "%.2f", product.price)) TL")
                            .font(.caption)
                            .strikethrough()
                            .foregroundColor(.secondary)
                        
                        if let percent = discountPercent, percent > 0 {
                            Text("%\(percent)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.n11Accent) // TEMA RENGİ
                                .cornerRadius(4)
                        }
                    }
                    
                    Text("\(String(format: "%.2f", discountPrice)) TL")
                        .font(.headline)
                        .bold()
                } else {
                    Text("\(String(format: "%.2f", product.price)) TL")
                        .font(.headline)
                        .bold()
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}
//  ProductSlide.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

