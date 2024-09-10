//
//  MirrorWidgetSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/05/24.
//

import SwiftUI
import Settings
import AVFoundation
import Defaults

struct MirrorWidgetSettingsView: View {
    
    enum Mode {
        case stopped, loading, mirroring
    }
    
    @State private var mode = Mode.stopped
    
    @Environment(\.cameraManager) var cameraManager
    
    @Default(.mirrorCameraInputWhenAvail) var mirrorCameraInputWhenAvail
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                mirrorSourceSection
                    .padding(.top, 16)
                mirrorVideoToggle
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            MirrorWidgetView(arrayPosition: .first, isSettingsPreview: true)
                .frame(150)
        }
        .padding(.top, 20)
        .frame(width: 450)
    }
    
    @ViewBuilder
    private var mirrorSourceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mirror source:")
                .fontWeight(.medium)
                .padding(.leading, 6)
            
            if cameraManager.allDevices.isEmpty {
                Text("No devices to preview from")
                    .frame(minWidth: 200, maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
            } else {
                devicesListView
            }
        }
    }
    
    @ViewBuilder
    private var devicesListView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(cameraManager.allDevices, id: \.self) { device in
                Label(device.localizedName, systemImage: "web.camera.fill")
                    .padding(EdgeInsets(top: 8, leading: 11, bottom: 8, trailing: 11))
                    .background(
                        Capsule(style: .continuous).fill(
                            cameraManager.selectedDevice == device ? Color.gray.opacity(0.3) : Color.clear
                        )
                    )
                    .opacity(cameraManager.selectedDevice == device ? 0.9 : 0.75)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cameraManager.selectedDevice = device
                    }
            }
        }
    }
    
    @ViewBuilder
    private var mirrorVideoToggle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: $mirrorCameraInputWhenAvail) {
                Text("Mirror video when available")
            }
            .toggleStyle(.checkbox)
            .padding(.leading, 6)
        }
    }
}
