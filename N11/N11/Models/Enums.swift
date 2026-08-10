import SwiftUI
import Combine
import Foundation
import UIKit


enum AppTab: String, CaseIterable {
    case home = "Ana Sayfa"
    case favorites = "Favorilerim"
    case cart = "Sepetim"
    case orders = "Siparişlerim"
    case account = "Hesap Bilgileri"
    
    var iconName: String {
        switch self {
        case .home: return "house"
        case .favorites: return "heart"
        case .cart: return "cart"
        case .orders: return "shippingbox"
        case .account: return "person"
        }
    }
}

enum SortOption: String, CaseIterable {
    case none = "Önerilen"
    case priceAsc = "En Düşük Fiyat"
    case priceDesc = "En Yüksek Fiyat"
    case topRated = "En Çok Değerlendirilenler"
}
//  Enums.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

