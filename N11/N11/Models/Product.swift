import SwiftUI
import Combine
import Foundation
import UIKit

struct ProductResponse: Codable, Sendable {
    let page: String?
    let nextPage: String?
    let publishedAt: String?
    let sponsoredProducts: [Product]?
    let products: [Product]?
    
    enum CodingKeys: String, CodingKey {
        case page, nextPage, sponsoredProducts, products
        case publishedAt = "published_at"
    }
}

struct Product: Codable, Identifiable, Sendable {
    let id: Int
    let title: String
    let image: String
    let price: Double
    let instantDiscountPrice: Double?
    let rate: Double?
    let sellerName: String?
    
    var validImageUrl: URL? {
        let cleanUrlString = image.replacingOccurrences(of: "{0}", with: "500")
        return URL(string: cleanUrlString)
    }
}

struct ProductDetail: Codable, Sendable {
    let title: String
    let description: String
    let images: [String]
    let price: Double
    let instantDiscountPrice: Double?
    let rate: Double?
    let sellerName: String?
    
    var validImageUrls: [URL] {
        return images.compactMap { imageString in
            let cleanUrlString = imageString.replacingOccurrences(of: "{0}", with: "500")
            return URL(string: cleanUrlString)
        }
    }
}
//  Product.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

