//
//  BatteryIconView.swift
//  NotchNook
//
//  Created by Hasan Sultan on 8/18/24.
//

import SwiftUI

struct BatteryIconView: View {
    @State private var BatteryOrACPower: Bool = false // Battery Power = true
    @State private var isCircleJiggling: Bool = false
    @State private var angle: Double = 0
    
    let powerSourceInfo = PowerSourceMonitor.shared
    
    var body: some View {
        ZStack {
            Color.clear
                .overlay {
                    if BatteryOrACPower {
                        Circle()
                            .trim(from: 0, to: normalizedBatteryCharge())
                            .stroke((powerSourceInfo.powerInfoStruct.BatteryPower?.currentStateOfCharge ?? 0) <= 20 ? Color.red : Color.green, lineWidth: 2)
                            .rotationEffect(.degrees(angle))
                            .onAppear {
                                startJiggleAnimation()
                            }
                            .padding(4)
                        Text(String(powerSourceInfo.powerInfoStruct.BatteryPower?.currentStateOfCharge ?? 0))
                            .foregroundColor(powerSourceInfo.powerInfoStruct.BatteryPower?.currentStateOfCharge ?? 0 <= 20 ? Color.red : Color.green)
                            .font(.system(size: 8))
                            .rotationEffect(.degrees(-angle))
                        
                    } else {
                        Group {
                            GeometryReader { geo in
                                Image(systemName: "bolt.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(geo.size * 0.60)
                                    .frame(width: geo.size.height, height: geo.size.height)
                                    .foregroundStyle(.yellow)
                                    .mask(
                                        Rectangle()
                                            .fill(Color.white)
                                            .scaleEffect(y: CGFloat(powerSourceInfo.powerInfoStruct.ACPower?.currentStateOfCharge ?? 0), anchor: .bottom)
                                            .animation(.easeInOut(duration: 0.5), value: CGFloat(powerSourceInfo.powerInfoStruct.ACPower?.currentStateOfCharge ?? 0))
                                    )
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
                .transition(.scaleAndBlur)
                .aspectRatio(1, contentMode: .fill)
        }
        .aspectRatio(0.8, contentMode: .fit)
        .transition(.scaleAndBlur)
        .onAppear {
            setDefaultPowerSource()
        }
    }
    private func setDefaultPowerSource() {
        if powerSourceInfo.powerInfoStruct.ACPower == nil {
            setForBatteryIcon()
        }
        else {
            setForACIcon()
        }
    }
    
    private func setForBatteryIcon() {
        BatteryOrACPower = true
    }
    private func setForACIcon() {
        BatteryOrACPower = false
    }
    private func normalizedBatteryCharge() -> CGFloat {
        guard let charge = powerSourceInfo.powerInfoStruct.BatteryPower?.currentStateOfCharge else {
            return 0
        }
        return min(max(CGFloat(charge), 0), 1)
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
            withAnimation(
                Animation.easeInOut(duration: animationDuration)
            ) {
                angle = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            isCircleJiggling = false
        }
    }
}



