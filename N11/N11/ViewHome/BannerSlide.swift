import SwiftUI
import Combine
import Foundation
import UIKit


// MARK: - Kampanya Banner Slaytı Modeli
struct BannerSlide: Identifiable {
    let id: Int
    let badgeText: String
    let title: String
    let priceText: String?
    let detail: ProductDetail?  // Zaten yüklü gerçek kampanya ürünü ise
    let product: Product?       // Temel ürün ise (tıklanınca detay sayfası yüklenecek)
}
// MARK: - Tek Bir Banner Kartı (Apple Store Tarzı Baloncuk ile Aynı Görsel Dil)
struct BannerSlideCard: View {
    let slide: BannerSlide
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var cartManager: CartManager
    
    var body: some View {
        Group {
            if let detail = slide.detail {
                NavigationLink(destination: FullProductDetailView(productDetail: detail, cartManager: cartManager)) {
                    cardBody
                }
            } else if let product = slide.product {
                NavigationLink(destination: ProductDetailLoader(baseProduct: product, favoritesManager: favoritesManager, cartManager: cartManager)) {
                    cardBody
                }
            } else {
                cardBody
            }
        }
    }
    
    private var cardBody: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(slide.badgeText)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.n11Accent) // TEMA RENGİ
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.black)
                    .cornerRadius(6)
                
                Text(slide.title)
                    .font(.headline)
                    .bold()
                    .lineLimit(2)
                    .foregroundColor(.white)
                
                if let priceText = slide.priceText {
                    Text(priceText)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.black)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.8))
                .font(.system(size: 16, weight: .bold))
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .background(
            Color.n11Accent
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.black, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 6, x: 0, y: 0)
        )
    }
}

// MARK: - Otomatik Kayan, Noktalı Göstergeli Kampanya Banner Carousel'ı
struct CampaignBannerCarousel: View {
    let slides: [BannerSlide]
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var cartManager: CartManager
    
    @State private var currentIndex = 0
    
    private let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 10) {
            TabView(selection: $currentIndex) {
                ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                    BannerSlideCard(slide: slide, favoritesManager: favoritesManager, cartManager: cartManager)
                        .tag(index)
                        .padding(.horizontal)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 160)
            .onReceive(timer) { _ in
                guard slides.count > 1 else { return }
                withAnimation(.easeInOut) {
                    currentIndex = (currentIndex + 1) % slides.count
                }
            }
            
            if slides.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.n11Accent : Color.gray.opacity(0.3)) // TEMA RENGİ
                            .frame(width: index == currentIndex ? 7 : 6, height: index == currentIndex ? 7 : 6)
                            .animation(.easeInOut, value: currentIndex)
                    }
                }
            }
        }
    }
}
//  BannerSlide.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

