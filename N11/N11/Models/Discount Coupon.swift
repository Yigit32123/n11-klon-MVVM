import SwiftUI
import Combine
import Foundation
import UIKit


// MARK: - İndirim Kodu Sistemi
// Kod 8 haneli: ilk 3 hane indirimin ne olduğunu taşır, kalan 5 hane rastgele harftir.
// TL indirimleri: sayı doğrudan yazılır -> "150", "250", "400"
// Yüzde indirimleri: 3 haneye sığmadığı için başına P konur -> "P10", "P20", "P25", "P50"
// Böylece kod okunduğu anda (henüz hiçbir yere kaydedilmeden) sistem ne indirimi olduğunu anlayabilir.
// Kodun kullanılıp kullanılmadığı ise CouponManager'ın sakladığı listede bu tam koda karşılık gelen
// "isUsed" alanıyla takip edilir; rastgele son 5 harf her kuponu birbirinden ayıran benzersiz anahtardır.

enum DiscountValue: Equatable {
    case amount(Int)
    case percent(Int)
    
    var displayText: String {
        switch self {
        case .amount(let tl): return "\(tl) TL"
        case .percent(let p): return "%\(p)"
        }
    }
}

enum DiscountCodeSystem {
    static func generateCode(prefix: String) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz"
        let suffix = String((0..<5).compactMap { _ in letters.randomElement() })
        return prefix.lowercased() + suffix
    }
    
    static func parse(_ rawCode: String) -> DiscountValue? {
        let code = rawCode.lowercased()
        guard code.count == 8 else { return nil }
        let prefix = String(code.prefix(3))
        if prefix.hasPrefix("p"), let percent = Int(prefix.dropFirst()) {
            return .percent(percent)
        }
        if let tl = Int(prefix) {
            return .amount(tl)
        }
        return nil
    }
}

struct DiscountCoupon: Codable, Identifiable, Equatable {
    var id: String { code }
    let code: String
    let prefix: String
    let createdAt: Date
    var isUsed: Bool = false
}
//  Discount Coupon.swift
//  ETdeneme
//
//  Created by yigit.korkmaz on 6.08.2026.
//

