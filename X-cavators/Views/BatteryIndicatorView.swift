//
//  BatteryIndicatorView.swift
//  X-cavators
//
//  Battery level indicator for the rover
//

import SwiftUI

struct BatteryIndicatorView: View {
    let batteryLevel: CGFloat
    let maxBattery: CGFloat
    let isCharging: Bool

    private var batteryPercentage: CGFloat {
        batteryLevel / maxBattery
    }

    private var batteryColor: Color {
        if isCharging {
            return .green
        } else if batteryPercentage > 0.5 {
            return .green
        } else if batteryPercentage > 0.25 {
            return .yellow
        } else {
            return .red
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Battery icon with level
            ZStack(alignment: .leading) {
                // Battery outline
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 60, height: 30)

                // Battery terminal (positive end)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 4, height: 16)
                    .offset(x: 62)

                // Battery fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(batteryColor)
                    .frame(width: max(0, 54 * batteryPercentage), height: 24)
                    .padding(.leading, 3)

                // Charging bolt icon
                if isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 30)
                }
            }

            // Battery percentage text
            HStack(spacing: 4) {
                if isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
                Text("\(Int(batteryPercentage * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.5))
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(batteryColor.opacity(0.5), lineWidth: 2)
                )
        )
    }
}

//#Preview {
//    VStack(spacing: 20) {
//        BatteryIndicatorView(batteryLevel: 100, maxBattery: 100, isCharging: false)
//        BatteryIndicatorView(batteryLevel: 60, maxBattery: 100, isCharging: false)
//        BatteryIndicatorView(batteryLevel: 30, maxBattery: 100, isCharging: true)
//        BatteryIndicatorView(batteryLevel: 10, maxBattery: 100, isCharging: false)
//    }
//    .padding()
//    .background(Color.gray)
//}
