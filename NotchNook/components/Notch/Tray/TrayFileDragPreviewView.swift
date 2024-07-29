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
            fileView.zIndex(1)
            
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
    
    var fileView: some View {
        VStack(spacing: 2) {
            TrayFileIconView(file: draggedFile)
                .frame(width: 42, height: 42)
            
            Text(draggedFile.nameTruncated)
                .frame(width: 56, alignment: .center)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.blue))
        }
        .foregroundStyle(.white)
        .padding(6)
        .frame(maxHeight: .infinity)
    }
}

