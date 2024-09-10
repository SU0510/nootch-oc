//
//  MirrorWidgetSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/05/24.
//

import SwiftUI
import Settings
import AVFoundation

struct MirrorWidgetSettingsView: View {
    
    enum Mode {
        case stopped, loading, mirroring
    }
    
    @State private var mode = Mode.stopped
    
    @Environment(\.cameraManager) var cameraManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                mirrorSourceSection
                    .padding(.top, 16)
                mirrorVideoToggle
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // this is currently causing the camera to never be turned off when first enabled because we don't have a way to know when the settings pane is closed, so it's commented out for now
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
            if cameraManager.isVideoMirroringSupported {
                Toggle(isOn: Binding(
                    get: { cameraManager.mirrorVideo },
                    set: { cameraManager.mirrorVideo = $0 }
                )) {
                    Text("Mirror video")
                }
                .toggleStyle(.checkbox)
                .padding(.leading, 6)
            }
        }
    }
}
