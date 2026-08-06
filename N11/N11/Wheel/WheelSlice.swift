import SwiftUI
import Combine
import Foundation
import UIKit


// MARK: - Çark Dilimi Şekli (8 eşit dilim, elle hesaplanmış yay - addArc belirsizliğinden kaçınmak için)

struct WheelSlice: Shape {
    let startAngle: Double // derece, saat 12 hizasından saat yönünde
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)

        let steps = 24
        for step in 0...steps {
            let t = Double(step) / Double(steps)
            let angleDeg = startAngle + (endAngle - startAngle) * t
            let angleRad = angleDeg * .pi / 180
            let x = center.x + radius * sin(angleRad)
            let y = center.y - radius * cos(angleRad)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.closeSubpath()
        return path
    }
}

//  WheelSlice.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//

