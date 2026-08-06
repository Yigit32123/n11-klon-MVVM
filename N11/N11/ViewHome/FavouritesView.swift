import SwiftUI
import Combine
import Foundation
import UIKit


// MARK: - Favoriler Sayfası
struct FavoritesView: View {
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var cartManager: CartManager
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if favoritesManager.favoriteProducts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Henüz favori ürününüz yok.")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(favoritesManager.favoriteProducts.indices, id: \.self) { index in
                            let product = favoritesManager.favoriteProducts[index]
                            NavigationLink(destination: ProductDetailLoader(baseProduct: product, favoritesManager: favoritesManager, cartManager: cartManager)) {
                                ProductCard(product: product, favoritesManager: favoritesManager)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 15)
                    .padding(.bottom, 130)
                }
            }
            .navigationTitle("Favorilerim")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

//  FavouritesView.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

