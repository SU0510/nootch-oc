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
        HStack(spacing: 10) {
            VStack(spacing: 30) {
                mirrorSourceSection
                mirrorVideoToggle
            }
            .frame(width: 270)
            
            // this is currently causing the camera to never be turned off when first enabled because we don't have a way to know when the settings pane is closed, so it's commented out for now
//            MirrorWidgetView(arrayPosition: .first, isSettingsPreview: true, width: 170)
        }
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private var mirrorSourceSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("Mirror source:")
                .font(.headline)
                .frame(width: 100, alignment: .trailing)
                .padding(5)
            
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
                Text(device.localizedName)
                    .padding(10)
                    .background(cameraManager.selectedDevice == device ? Color.gray.opacity(0.3) : Color.clear)
                    .cornerRadius(4)
                    .onTapGesture {
                        cameraManager.selectedDevice = device
                    }
                    .font(.system(size: 12))
                    .frame(height: 30)
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
                .padding(.vertical, 4)
            }
        }
    }
}
