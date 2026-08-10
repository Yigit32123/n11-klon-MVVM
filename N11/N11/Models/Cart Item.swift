import SwiftUI
import Combine
import Foundation
import UIKit


struct CartItem: Identifiable, Codable {
    var id = UUID()
    let product: Product
    var quantity: Int
}
//  CartItem.swift
//  N11
//  Created by yigit.korkmaz on 6.08.2026.
//

