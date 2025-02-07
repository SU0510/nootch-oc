//
//  BatteryLiveActivitySettingsView.swift
//  NotchNook
//
//  Created by Hasan Sultan on 8/18/24.
//

import SwiftUI
import Settings
import Defaults

struct BatteryLiveActivitySettingsView: View {
    @Default(.batteryLiveActivitySettings) private var batteryLiveActivitySettings
    
    var body: some View {
        let contentMaxW: Double = 400
        // TODO: arrumar
        // TODO: essas opções tem que ser habilitáveis
        Settings.Container(contentWidth: 520.0, minimumLabelWidth: 200) {
            Settings.Section(title: String(localized: "Notify Charge Increase on:"), bottomDivider: true) {
                HStack {
                    Text("\(batteryLiveActivitySettings.notifyOnChargePercentage)%")
                        .font(.headline)
                        .frame(maxWidth: contentMaxW * 0.2, alignment: .leading)
                    
                    Slider(value: Binding(get: {
                        Double(batteryLiveActivitySettings.notifyOnChargePercentage)
                    }, set: { newValue in
                        batteryLiveActivitySettings.notifyOnChargePercentage = UInt(newValue)
                    }), in: 1...100, step: 1)
                    .frame(maxWidth: contentMaxW * 0.8)
                }
            }
            
            Settings.Section(title: String(localized: "Time Left Notification every:"), bottomDivider: true) {
                
                HStack {
                    Text("\(Int(batteryLiveActivitySettings.notifyTimeLeftOnBattery)) minutes")
                        .font(.headline)
                        .frame(maxWidth: contentMaxW * 0.3, alignment: .leading)
                    
                    Slider(value: Binding(get: {
                        Double(batteryLiveActivitySettings.notifyTimeLeftOnBattery)
                    }, set: { newValue in
                        batteryLiveActivitySettings.notifyTimeLeftOnBattery = UInt(newValue)
                    }), in: 0...100, step: 1)
                    .frame(maxWidth: contentMaxW * 0.7)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
