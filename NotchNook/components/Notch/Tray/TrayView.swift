//
//  TrayView.swift
//  Notchway
//
//  Created by Igor Marcossi on 13/05/24.
//

import SwiftUI
import Defaults

struct TrayView: View {
    static let id = "sheld"
    
    var hovered: Bool
    var full: Bool
    
    @Environment(\.traySettings) private var traySettings
    @Environment(\.tray) private var tray
    
    var body: some View {
        let files = tray.files
        HStack {
            Group {
                if files.count > 0 {
                    TrayFilesScrollView(files: files, selectedFiles: tray.selectedFiles, selectFile: tray.selectFile)
                } else {
                    TrayEmptyView(hovered: hovered, centered: true)
                }
            }
            .transition(.scaleAndBlur(anchor: .top))
        }
        .frame(traySettings.size.screenPtsCGSize, .leading)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    (hovered ? Color.blue : Color.nonShockingWhite).opacity(hovered ? 0.5 : 0.1),
                    style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [6, 12])
                )
        }
        .geometryGroup()
        .animation(.easeOut(duration: 0.2), value: hovered)
        .onAppear {
            tray.setupEventMonitors()
        }
        .onDisappear {
            tray.stopMonitoringEvents()
        }
    }
}

