import SwiftUI
import Combine
import Foundation
import UIKit


struct WheelPrize: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let codePrefix: String?
}

let wheelPrizes: [WheelPrize] = [
    WheelPrize(label: "Kazanamadın", codePrefix: nil),
    WheelPrize(label: "150 TL", codePrefix: "150"),
    WheelPrize(label: "250 TL", codePrefix: "250"),
    WheelPrize(label: "400 TL", codePrefix: "400"),
    WheelPrize(label: "%20", codePrefix: "P20"),
    WheelPrize(label: "%50", codePrefix: "P50"),
    WheelPrize(label: "%10", codePrefix: "P10"),
    WheelPrize(label: "%25", codePrefix: "P25")
]
//  Wheel Prize.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

