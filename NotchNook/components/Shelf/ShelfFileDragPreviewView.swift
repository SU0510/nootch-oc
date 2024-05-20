//
//  ShelfFileDragPreviewView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct ShelfFileDragPreviewView: View {
    let draggedFile: ShelfFile
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ShelfFileView(file: draggedFile, isSelected: true, preview: true)
              .zIndex(1)
            
            if Shelf.shared.selectedFiles.count > 1 {
                Text("+\(Shelf.shared.selectedFiles.count - 1)")
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

