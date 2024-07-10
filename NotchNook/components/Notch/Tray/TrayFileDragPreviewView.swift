//
//  TrayFileDragPreviewView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct TrayFileDragPreviewView: View {
    let draggedFile: TrayFile
    
    @Environment(\.tray) private var tray
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TrayFileView(file: draggedFile, isSelected: true, isPreview: true)
              .zIndex(1)
            
            if tray.selectedFiles.count > 1 {
                Text("+\(tray.selectedFiles.count - 1)")
                    .font(.system(size: 12))
                    .fontWeight(.semibold)
                    .frame(24)
                    .background(.bar, in: Circle())
                    .padding(.all, 4)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

