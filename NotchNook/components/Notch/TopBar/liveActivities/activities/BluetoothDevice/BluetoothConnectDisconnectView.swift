//
//  BluetoothConnectDisconnectView.swift
//  NotchNook
//
//  Created by Hasan Sultan on 9/3/24.
//

import SwiftUI

struct BluetoothConnectDisconnectView: View {
    var body: some View {
        // TODO: MUDAR PRO COMPORTAMENTO DO iOS
        if let battery = BluetoothManager.shared.currentDeviceBattery {
            Text("\(battery)%")
        } else {
            Image(.bluetooth)
                .resizable()
                .scaledToFit()
                .padding(5)
                .foregroundStyle(.blue)
        }
    }
}
