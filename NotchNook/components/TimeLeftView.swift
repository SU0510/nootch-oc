//
//  TimeLeftView.swift
//  NotchNook
//
//  Created by Hasan Sultan on 9/1/24.
//

import SwiftUI

struct TimeLeftView: View {
    
    let batteryStatus: PowerMonitor.BatteryStatus?
    
    // TODO: MUDAR PRO COMPORTAMENTO DO iOS, TESTAR E REMOVER TEST CASES
    
//        let batteryStatus: PowerMonitor.BatteryStatus? = .init(
//            percentage: 15,
//            isCharging: true,
//            minutesUntilEmpty: nil,
//            minutesUntilFull: 120
//        )
    
    //     let batteryStatus: PowerMonitor.BatteryStatus? = .init(
    //         percentage: 85,
    //         isCharging: false,
    //         minutesUntilEmpty: 180,
    //         minutesUntilFull: nil
    //     )
    
//         let batteryStatus: PowerMonitor.BatteryStatus? = .init(
//             percentage: 100,
//             isCharging: true,
//             minutesUntilEmpty: nil,
//             minutesUntilFull: 0
//         )
    
//    let batteryStatus: PowerMonitor.BatteryStatus? = .init(
//        percentage: 5,
//        isCharging: false,
//        minutesUntilEmpty: 10,
//        minutesUntilFull: nil
//    )
    
    // let batteryStatus: PowerMonitor.BatteryStatus? = nil
    
    var body: some View {
        ZStack {
            Color.clear
                .overlay {
                    Text(batteryStatus?.formattedTimeRemaining ?? "")
                        .font(.system(size: 8))
                        .frame(maxHeight: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                }
                .transition(.scaleAndBlur)
                .aspectRatio(1, contentMode: .fit)
        }
        .aspectRatio(1, contentMode: .fit)
        .transition(.scaleAndBlur)
    }
}
