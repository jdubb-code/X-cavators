//
//  HomeBaseView.swift
//  X-cavators
//
//  Visual representation of the home base
//

import SwiftUI

struct HomeBaseView: View {
    let homeBase: HomeBase
    let isRoverInRange: Bool

    var body: some View {
        ZStack {
            // Recharge radius indicator
            Circle()
                .stroke(
                    isRoverInRange ? Color.green.opacity(0.3) : Color.blue.opacity(0.2),
                    lineWidth: 2
                )
                .frame(width: homeBase.rechargeRadius * 2, height: homeBase.rechargeRadius * 2)

            // Recharge radius fill (when rover is in range)
            if isRoverInRange {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: homeBase.rechargeRadius * 2, height: homeBase.rechargeRadius * 2)
            }

            // Home base platform
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.2, blue: 0.3),
                            Color(red: 0.15, green: 0.15, blue: 0.25)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: homeBase.size.width, height: homeBase.size.height)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.6), lineWidth: 3)
                )

            // Home icon
            Image(systemName: "house.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue.opacity(0.8))

            // Charging indicator
            if isRoverInRange {
                VStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("CHARGING")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.7))
                    )
                    .offset(y: homeBase.size.height / 2 + 20)
                }
            }
        }
        .position(homeBase.position)
    }
}

//#Preview {
//    ZStack {
//        Color.black
//        HomeBaseView(
//            homeBase: HomeBase(position: CGPoint(x: 200, y: 200)),
//            isRoverInRange: true
//        )
//    }
//}
