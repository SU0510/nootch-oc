//
//  DropAreaTrayTargetView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/05/24.
//

import SwiftUI

struct DropAreaTrayTargetView: View {
    var hovered: Bool
    
    @Environment(\.tray) private var tray
    
    var body: some View {
        let files = tray.files
        HStack {
            TrayEmptyView(hovered: hovered, centered: false)
            
            Spacer()
            
            if files.count > 0 {
                TrayFilesGridPreviewView(files: Array(files.prefix(4)))
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    (hovered ? Color.blue : Color.white).opacity(hovered ? 0.5 : 0.1),
                    style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [6, 12])
                )
        }
        .geometryGroup()
        .animation(.easeOut(duration: 0.2), value: hovered)
    }
}
