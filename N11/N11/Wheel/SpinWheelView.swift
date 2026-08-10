import SwiftUI
import Combine
import Foundation
import UIKit

// MARK: - Şans Çarkı (Bana Ne Var)
struct SpinWheelView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var couponManager = CouponManager()
    @State private var shuffledPrizes: [WheelPrize] = wheelPrizes.shuffled()
    @State private var rotation: Double = 0
    @State private var isSpinning: Bool = false
    @State private var lastDragAngle: Double? = nil
    @State private var lastDragTime: Date = Date()
    @State private var angularVelocity: Double = 0 // derece / saniye
    @State private var showResult: Bool = false
    @State private var resultPrize: WheelPrize? = nil
    @State private var resultCoupon: DiscountCoupon? = nil
    @State private var didCopyCode: Bool = false
    private let wheelDiameter: CGFloat = 300
    private let sliceAngle: Double = 45 // 360 / 8
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                VStack(spacing: 36) {
                    Text("Parmağını basılı tutup çevir, nerede durursa onu kazan!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                    ZStack {
                        // Sabit gösterge (ok) - dönmez
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.black)
                            .offset(y: -wheelDiameter / 2 - 8)
                            .zIndex(2)
                        // Sadece görsel: dönen çark yüzü
                        wheelFace
                            .rotationEffect(.degrees(rotation))
                            .allowsHitTesting(false)
                        // Sabit, görünmez sürükleme katmanı - açı hesabı hep bunun üzerinden yapılır
                        // böylece çarkın kendi rotationEffect'i dokunma koordinatlarını etkilemez.
                        Color.clear
                            .contentShape(Circle())
                            .frame(width: wheelDiameter, height: wheelDiameter)
                            .gesture(dragGesture)
                    }
                    .frame(width: wheelDiameter, height: wheelDiameter + 40)
                    Text(isSpinning ? "Çark dönüyor..." : "Başlamak için çarka dokun ve çevir")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                if showResult {
                    resultOverlay
                }
            }
            .navigationTitle("Bana Ne Var")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: Çark Görseli
    private var wheelFace: some View {
        ZStack {
            ForEach(Array(shuffledPrizes.enumerated()), id: \.offset) { index, prize in
                let start = Double(index) * sliceAngle
                let end = start + sliceAngle
                let mid = start + sliceAngle / 2
                let isBlackSlice = index % 2 == 0
                WheelSlice(startAngle: start, endAngle: end)
                    .fill(isBlackSlice ? Color.black : Color.n11Accent)
                Text(prize.label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isBlackSlice ? Color.n11Accent : Color.black)
                    .multilineTextAlignment(.center)
                    .frame(width: 64)
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(y: -wheelDiameter * 0.32)
                    .rotationEffect(.degrees(mid))
            }
            Circle()
                .fill(Color.white)
                .frame(width: 54, height: 54)
                .overlay(Circle().stroke(Color.black, lineWidth: 2))
                .overlay(
                    Image(systemName: "gift.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.n11Accent)
                )
        }
        .frame(width: wheelDiameter, height: wheelDiameter)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.black, lineWidth: 4))
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
    
    // MARK: Basılı Tutup Çevirme Hareketi
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !isSpinning else { return }
                let center = CGPoint(x: wheelDiameter / 2, y: wheelDiameter / 2)
                let currentAngle = rawAngle(from: center, to: value.location)
                let now = Date()
                if let last = lastDragAngle {
                    var delta = currentAngle - last
                    if delta > 180 { delta -= 360 }
                    if delta < -180 { delta += 360 }
                    rotation += delta
                    let dt = now.timeIntervalSince(lastDragTime)
                    if dt > 0 {
                        let instantVelocity = delta / dt
                        angularVelocity = (angularVelocity * 0.7) + (instantVelocity * 0.3)
                    }
                }
                lastDragAngle = currentAngle
                lastDragTime = now
            }
            .onEnded { _ in
                guard !isSpinning else { return }
                lastDragAngle = nil
                spinToStop()
            }
    }
    
    private func rawAngle(from center: CGPoint, to point: CGPoint) -> Double {
        let dx = point.x - center.x
        let dy = point.y - center.y
        var degrees = atan2(dy, dx) * 180 / .pi
        if degrees < 0 { degrees += 360 }
        return degrees
    }
    
    // MARK: Parmak Kalkınca Yavaşlayarak Durma
    private func spinToStop() {
        isSpinning = true
        let direction: Double = angularVelocity >= 0 ? 1 : -1
        let baseSpeed = min(max(abs(angularVelocity), 90), 1800) // Çok yavaş ya da aşırı hızlı olmasını engeller
        let extraTurns = Double.random(in: 3...6) * 360
        let randomOffset = Double.random(in: 0..<360)
        let travel = extraTurns + (baseSpeed * 0.5) + randomOffset
        let finalRotation = rotation + (direction * travel)
        let duration = 4.0
        withAnimation(.timingCurve(0.12, 0.85, 0.25, 1.0, duration: duration)) {
            rotation = finalRotation
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            finishSpin(at: finalRotation)
        }
    }
    
    private func finishSpin(at finalRotation: Double) {
        let normalized = finalRotation.truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        let pointerAngleOnWheel = (360 - positive).truncatingRemainder(dividingBy: 360)
        let index = Int(pointerAngleOnWheel / sliceAngle) % shuffledPrizes.count
        let prize = shuffledPrizes[index]
        resultPrize = prize
        resultCoupon = couponManager.generateCoupon(for: prize)
        didCopyCode = false
        isSpinning = false
        angularVelocity = 0
        withAnimation {
            showResult = true
        }
    }
    
    // MARK: Sonuç Kartı
    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                if let prize = resultPrize, let coupon = resultCoupon {
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.n11Accent)
                    Text("Tebrikler!")
                        .font(.title2).bold()
                    Text("\(prize.label) değerinde kupon kazandınız.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    HStack {
                        Text(coupon.code.uppercased())
                            .font(.system(.title3, design: .monospaced))
                            .bold()
                            .kerning(2)
                        Button(action: {
                            UIPasteboard.general.string = coupon.code.uppercased()
                            didCopyCode = true
                        }) {
                            Image(systemName: didCopyCode ? "checkmark.circle.fill" : "doc.on.doc")
                                .foregroundColor(didCopyCode ? .green : .n11Accent)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.06))
                    .cornerRadius(10)
                    if didCopyCode {
                        Text("Kod kopyalandı!")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Image(systemName: "face.dashed")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Bu sefer olmadı")
                        .font(.title2).bold()
                    Text("Kazanamadınız, tekrar deneyebilirsiniz.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Button(action: {
                    withAnimation {
                        showResult = false
                    }
                    shuffledPrizes = wheelPrizes.shuffled()
                }) {
                    Text("Tamam")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.n11Accent)
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(20)
            .padding(.horizontal, 40)
            .shadow(radius: 20)
        }
    }
}
//  SpinWheelView.swift
//  N11
//
//  Created by yigit.korkmaz on 6.08.2026.
//
