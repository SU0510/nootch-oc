//
//  BluetoothDeviceIconView.swift
//  NotchNook
//
//  Created by Hasan Sultan on 9/3/24.
//


import SwiftUI

struct BluetoothDeviceIconView: View {
    
    @State var iconName: String = "airpods"
    
    var body: some View {
        Image(systemName: iconName)
            .resizable()
            .scaledToFit()
            .padding(5)
            .foregroundColor(.white)
            .onAppear {
                iconName = BluetoothManager.shared.currentDeviceIcon
            }
    }
}
