//
//  TimeLeftView.swift
//  NotchNook
//
//  Created by Hasan Sultan on 9/1/24.
//

import SwiftUI

struct TimeLeftView: View {
    
    @State private var timeLeftToChargeto100: Int = 0
    @State private var timeToEmpty: Int = 0
    let powerSourceInfo = PowerSourceMonitor.shared
    
    var body: some View {
        ZStack {
            Color.clear
                .overlay {
                    Group {
                        if timeToEmpty != 0 {
                            if timeToEmpty < 60 {
                                Text(String(timeToEmpty) + "m")
                                    .font(.system(size: 8))
                            }
                            else {
                                Text(String(timeToEmpty / 60) + "h")
                                    .font(.system(size: 8))
                            }
                        } else {
                            // Match this with the defaults notification
                            if timeLeftToChargeto100 > 60 {
                                Text(String(timeLeftToChargeto100 / 60) + "h")
                                    .font(.system(size: 8))
                            }else {
                                Text(String(timeLeftToChargeto100) + "m")
                                    .font(.system(size: 8))
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                }
                .transition(.scaleAndBlur)
                .aspectRatio(1, contentMode: .fit)
        }
        .aspectRatio(1, contentMode: .fit)
        .transition(.scaleAndBlur)
        .onAppear {
            setStateOfChargeORtimeLeftToCharge()
       }
    }
    private func setStateOfChargeORtimeLeftToCharge() {
        (powerSourceInfo.powerInfoStruct.BatteryPower != nil) ? setForTimeToEmpty(): setForTimeRemainingToCompleteCharge()
    }
    private func setForTimeToEmpty() {
        timeLeftToChargeto100 = 0
        timeToEmpty = (powerSourceInfo.powerInfoStruct.BatteryPower?.timeToEmpty)!
    }
    private func setForTimeRemainingToCompleteCharge() {
        timeToEmpty = 0
        timeLeftToChargeto100 = (powerSourceInfo.powerInfoStruct.ACPower?.timeLeftTo100)!
    }
}

