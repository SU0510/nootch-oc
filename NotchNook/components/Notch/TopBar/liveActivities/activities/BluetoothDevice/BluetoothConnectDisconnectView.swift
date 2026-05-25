//
//  BluetoothConnectDisconnectView.swift
//  NotchNook
//
//  Created by Hasan Sultan on 9/3/24.
//

import SwiftUI

struct BluetoothConnectDisconnectView: View {
    
    private var manager: BluetoothManager { BluetoothManager.shared }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            let name = manager.currentDeviceName.isEmpty ? "Bluetooth" : manager.currentDeviceName
            Text(name)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
            HStack(spacing: 3) {
                Image(systemName: manager.currentDeviceIsConnecting ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(manager.currentDeviceIsConnecting ? .green : .red)
                Text(manager.currentDeviceIsConnecting ? "Connected" : "Disconnected")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.nonShockingWhite)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
