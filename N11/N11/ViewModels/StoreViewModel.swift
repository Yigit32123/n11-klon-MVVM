import SwiftUI
import Combine
import Foundation
import UIKit

class StoreViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var sponsoredProducts: [Product] = []
    @Published var detailedProduct: ProductDetail? = nil
    
    @Published var currentPage = 1
    @Published var isLoadingMore = false
    
    init() {
        fetchListing(page: 1)
        fetchProductDetail(productId: 12333)
    }
    
    func fetchListing(page: Int) {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        
        guard let url = URL(string: "https://private-d3ae2-n11case.apiary-mock.com/listing/\(page)") else {
            isLoadingMore = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingMore = false
                guard let data = data, error == nil else {
                    self.simulateInfiniteScroll()
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(ProductResponse.self, from: data)
                    let fetchedProducts = decodedResponse.products ?? []
                    
                    if fetchedProducts.isEmpty {
                        self.simulateInfiniteScroll()
                    } else {
                        if page == 1 {
                            self.products = fetchedProducts
                            self.sponsoredProducts = decodedResponse.sponsoredProducts ?? []
                        } else {
                            self.products.append(contentsOf: fetchedProducts)
                        }
                        self.currentPage = page
                    }
                    
                } catch {
                    print("Listing JSON Decode Hatası (Sayfa \(page)): \(error)")
                    self.simulateInfiniteScroll()
                }
            }
        }.resume()
    }
    
    private func simulateInfiniteScroll() {
        if !self.products.isEmpty {
            let loopData = self.products.prefix(10)
            self.products.append(contentsOf: loopData)
            self.currentPage += 1
        }
    }
    
    func fetchProductDetail(productId: Int) {
        guard let url = URL(string: "https://private-d3ae2-n11case.apiary-mock.com/product?productId=\(productId)") else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                do {
                    let decodedDetail = try JSONDecoder().decode(ProductDetail.self, from: data)
                    self.detailedProduct = decodedDetail
                } catch {
                    print("Detay JSON Decode Hatası: \(error)")
                }
            }
        }.resume()
    }
    
    func loadNextPage() {
        guard !isLoadingMore else { return }
        fetchListing(page: currentPage + 1)
    }
}
//  StoreViewModel.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

