import SwiftUI
import Combine
import Foundation
import UIKit

// MARK: - Kupon Yöneticisi (üretim + saklama + kullanıldı/kullanılmadı takibi)
final class CouponManager: ObservableObject {
    @Published private(set) var coupons: [DiscountCoupon] = []

    private let storageKey = "n11klon_generated_coupons"

    init() {
        load()
    }

    /// Verilen ödül için 8 haneli benzersiz kupon üretir, saklar ve döner.
    /// "Kazanamadın" için (codePrefix nil) kupon üretilmez.
    @discardableResult
    func generateCoupon(for prize: WheelPrize) -> DiscountCoupon? {
        guard let prefix = prize.codePrefix else { return nil }

        var newCode = DiscountCodeSystem.generateCode(prefix: prefix)
        while coupons.contains(where: { $0.code == newCode }) {
            newCode = DiscountCodeSystem.generateCode(prefix: prefix)
        }

        let coupon = DiscountCoupon(code: newCode, prefix: prefix.lowercased(), createdAt: Date(), isUsed: false)
        coupons.append(coupon)
        save()
        return coupon
    }

    /// Kuponu kullanıldı olarak işaretler (sepette/ödemede kupon uygulanırken çağrılabilir).
    func markUsed(code: String) {
        guard let index = coupons.firstIndex(where: { $0.code == code }) else { return }
        coupons[index].isUsed = true
        save()
    }

    func isUsed(code: String) -> Bool {
        coupons.first(where: { $0.code == code })?.isUsed ?? false
    }

    private func save() {
        if let data = try? JSONEncoder().encode(coupons) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([DiscountCoupon].self, from: data) {
            coupons = decoded
        }
    }
}
//  CouponManager.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

