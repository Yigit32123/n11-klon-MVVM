import SwiftUI
import Combine
import Foundation
import UIKit


// MARK: - Dinamik Ürün Detay Yükleyici
struct ProductDetailLoader: View {
    let baseProduct: Product
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var cartManager: CartManager
    
    @State private var productDetail: ProductDetail?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Ürün bilgileri getiriliyor...")
                        .font(.callout)
                        .foregroundColor(.gray)
                }
            } else if let detail = productDetail {
                FullProductDetailView(baseProduct: baseProduct, productDetail: detail, cartManager: cartManager)
            } else {
                Text("Ürün bilgisine ulaşılamadı.")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            fetchDetail()
        }
    }
    
    private func fetchDetail() {
        guard let url = URL(string: "https://private-d3ae2-n11case.apiary-mock.com/product?productId=\(baseProduct.id)") else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = data {
                    do {
                        self.productDetail = try JSONDecoder().decode(ProductDetail.self, from: data)
                    } catch {
                        print("Detay sayfası parse hatası: \(error)")
                    }
                }
            }
        }.resume()
    }
}

//  ProductDetailLoader.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

