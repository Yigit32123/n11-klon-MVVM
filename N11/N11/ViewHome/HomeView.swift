import SwiftUI
import Combine
import Foundation
import UIKit


// MARK: - Ana Sayfa (HomeView)
struct HomeView: View {
    @ObservedObject var viewModel: StoreViewModel
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var cartManager: CartManager
    
    @State private var searchText = ""
    @State private var selectedCategory = "Tümü"
    @State private var selectedSort: SortOption = .none
    
    let categories = ["Tümü", "Elektronik", "Moda", "Süpermarket", "Ev & Yaşam"]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var bannerSlides: [BannerSlide] {
        var slides: [BannerSlide] = []
        
        if let detail = viewModel.detailedProduct {
            slides.append(BannerSlide(id: 0, badgeText: "Günün Fırsatı", title: detail.title, priceText: nil, detail: detail, product: nil))
        }
        
        let extras = Array(viewModel.sponsoredProducts.prefix(3))
        for (index, product) in extras.enumerated() {
            let badge = index == 0 ? "Süper Fiyat" : (index == 1 ? "Ücretsiz Kargo" : "Flaş Ürün")
            let priceValue = product.instantDiscountPrice ?? product.price
            let priceText = "\(String(format: "%.2f", priceValue)) TL'den başlayan fiyatlarla"
            slides.append(BannerSlide(id: index + 1, badgeText: badge, title: product.title, priceText: priceText, detail: nil, product: product))
        }
        
        return slides
    }
    
    var filteredAndSortedProducts: [Product] {
        var combinedProducts = viewModel.products
        
        for sponsored in viewModel.sponsoredProducts {
            if !combinedProducts.contains(where: { $0.id == sponsored.id }) {
                combinedProducts.append(sponsored)
            }
        }
        
        var result = combinedProducts
        
        if !searchText.isEmpty {
            let searchTerms = searchText.searchNormalized.split(separator: " ").map { String($0) }
            result = result.filter { product in
                let normalizedTitle = product.title.searchNormalized
                return searchTerms.allSatisfy { term in
                    normalizedTitle.contains(term)
                }
            }
        }
        
        if selectedCategory != "Tümü" {
            let keywords: [String]
            switch selectedCategory {
            case "Elektronik": keywords = ["telefon", "bilgisayar", "kulaklik", "tv", "apple", "samsung", "xiaomi", "iphone", "kilif"]
            case "Moda": keywords = ["ayakkabi", "canta", "tisort", "giyim", "kiyafet", "pantolon"]
            case "Süpermarket": keywords = ["kahve", "deterjan", "bebek", "bez", "gida", "atistirmalik"]
            case "Ev & Yaşam": keywords = ["mobilya", "dekorasyon", "masa", "lamba"]
            default: keywords = []
            }
            
            if !keywords.isEmpty {
                result = result.filter { product in
                    let normalizedTitle = product.title.searchNormalized
                    return keywords.contains { keyword in
                        normalizedTitle.contains(keyword)
                    }
                }
            }
        }
        
        switch selectedSort {
        case .priceAsc:
            result.sort { ($0.instantDiscountPrice ?? $0.price) < ($1.instantDiscountPrice ?? $1.price) }
        case .priceDesc:
            result.sort { ($0.instantDiscountPrice ?? $0.price) > ($1.instantDiscountPrice ?? $1.price) }
        case .topRated:
            result.sort { ($0.rate ?? 0) > ($1.rate ?? 0) }
        case .none:
            break
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { category in
                                Text(category)
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.n11Accent : Color.gray.opacity(0.1)) // TEMA RENGİ
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(20)
                                    .onTapGesture {
                                        withAnimation { selectedCategory = category }
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    
                    if !bannerSlides.isEmpty {
                        CampaignBannerCarousel(slides: bannerSlides, favoritesManager: favoritesManager, cartManager: cartManager)
                    }
                    
                    Divider()
                    
                    if !viewModel.sponsoredProducts.isEmpty && searchText.isEmpty && selectedCategory == "Tümü" {
                        VStack(alignment: .leading) {
                            Text("Bu ürünleri gördünüz mü?")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(viewModel.sponsoredProducts.indices, id: \.self) { index in
                                        let product = viewModel.sponsoredProducts[index]
                                        NavigationLink(destination: ProductDetailLoader(baseProduct: product, favoritesManager: favoritesManager, cartManager: cartManager)) {
                                            ProductCard(product: product, favoritesManager: favoritesManager)
                                                .frame(width: 160)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        Divider()
                    }
                    
                    HStack {
                        Text("Tüm Ürünler")
                            .font(.headline)
                        Spacer()
                        Menu {
                            Picker("Sıralama", selection: $selectedSort) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.arrow.down")
                                Text(selectedSort.rawValue)
                            }
                            .font(.subheadline)
                            .foregroundColor(.n11Accent) // TEMA RENGİ
                        }
                    }
                    .padding(.horizontal)
                    
                    if filteredAndSortedProducts.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("Aradığınız kriterlere uygun ürün bulunamadı.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(filteredAndSortedProducts.indices, id: \.self) { index in
                                let product = filteredAndSortedProducts[index]
                                NavigationLink(destination: ProductDetailLoader(baseProduct: product, favoritesManager: favoritesManager, cartManager: cartManager)) {
                                    ProductCard(product: product, favoritesManager: favoritesManager)
                                        .onAppear {
                                            if index == filteredAndSortedProducts.count - 1 {
                                                viewModel.loadNextPage()
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        
                        if viewModel.isLoadingMore {
                            ProgressView("Daha fazla yükleniyor...")
                                .padding()
                                .frame(maxWidth: .infinity)
                        }
                        
                        Spacer().frame(height: 130)
                    }
                }
            }
            .navigationTitle("n11 Klon")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Ürün, kategori veya marka ara")
        }
    }
}
//  HomeView.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

