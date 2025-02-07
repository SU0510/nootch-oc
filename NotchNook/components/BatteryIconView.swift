//
//  BatteryIconView.swift
//  NotchNook
//
//  Created by Hasan Sultan on 8/18/24.
//

import SwiftUI

struct BatteryIconView: View {
    
    @State private var isCircleJiggling: Bool = false
    @State private var angle: Double = 0
    
    // TODO: MUDAR PRO COMPORTAMENTO DO iOS, TESTAR E REMOVER TEST CASES
    
    // HARDCODED TEST CASES - DELETE LATER
    // Uncomment one at a time to test
    
    let batteryStatus: PowerMonitor.BatteryStatus?
//    = .init(
//        percentage: 15,
//        isCharging: true,
//        minutesUntilEmpty: nil,
//        minutesUntilFull: 120
//    )
    
    //     let batteryStatus: PowerMonitor.BatteryStatus? = .init(
    //         percentage: 85,
    //         isCharging: false,
    //         minutesUntilEmpty: 180,
    //         minutesUntilFull: nil
    //     )
    
    //     let batteryStatus: PowerMonitor.BatteryStatus? = .init(
    //         percentage: 100,
    //         isCharging: true,
    //         minutesUntilEmpty: nil,
    //         minutesUntilFull: 0
    //     )
    
    //     let batteryStatus: PowerMonitor.BatteryStatus? = .init(
    //         percentage: 5,
    //         isCharging: false,
    //         minutesUntilEmpty: 10,
    //         minutesUntilFull: nil
    //     )
    
    // let batteryStatus: PowerMonitor.BatteryStatus? = nil
    
    var color: Color {
        guard let batteryStatus else { return .green }
        return batteryStatus.percentage < 20 && !batteryStatus.isCharging ? .red : .green
    }
    
    var body: some View {
        ZStack {
            Color.clear
                .overlay {
                    let percentage = batteryStatus?.percentage ?? 0
                    
                    if percentage == 100 {
                        // MARK: Green bolt inside circle
                        GeometryReader { geo in
                            Image(systemName: "bolt.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(geo.size * 0.60)
                                .frame(width: geo.size.height, height: geo.size.height)
                                .foregroundStyle(.green)
                        }
                        .frame(maxHeight: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                    } else {
                        // MARK: Battery circle
                        ZStack {
                            // Background circle (full, transparent)
                            Circle()
                                .stroke(color.opacity(0.3), lineWidth: 2)
                                .padding(4)
                            
                            // Foreground percentage circle
                            Circle()
                                .trim(from: 0, to: normalizedBatteryCharge)
                                .stroke(color, lineWidth: 2)
                                .rotationEffect(.degrees(-90))
                                .rotationEffect(.degrees(angle))
                                .onAppear { startJiggleAnimation() }
                                .padding(4)
                                .background(
                                    Group {
                                        if batteryStatus?.isCharging ?? false {
                                            // Charging bolt
                                            Image(systemName: "bolt.fill")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 10, height: 10)
                                                .foregroundStyle(.green)
                                                .padding(2)
                                        } else {
                                            // Percentage text
                                            Text("\(percentage)%")
                                                .font(.system(size: 6))
                                                .rotationEffect(.degrees(-angle))
                                                .padding(1)
                                        }
                                    }
                                )
                        }
                    }
                }
                .transition(.scaleAndBlur)
                .aspectRatio(1, contentMode: .fill)
        }
        .aspectRatio(0.8, contentMode: .fit)
        .transition(.scaleAndBlur)
    }
    
    private var normalizedBatteryCharge: CGFloat {
        guard let percentage = batteryStatus?.percentage else { return 0 }
        return CGFloat(percentage) / 100
    }
    
    private func startJiggleAnimation() {
        guard !isCircleJiggling else { return }
        isCircleJiggling = true
        let animationDuration = 0.1
        let totalJiggles: Double = 3
        
        withAnimation(
            Animation.easeInOut(duration: animationDuration)
                .repeatCount(Int(totalJiggles * 2), autoreverses: true)
        ) {
            angle = 15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + totalJiggles * animationDuration * 2) {
            withAnimation(.easeInOut(duration: animationDuration)) {
                angle = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            isCircleJiggling = false
        }
    }
}
