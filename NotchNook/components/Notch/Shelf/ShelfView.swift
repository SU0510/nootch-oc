//
//  ShelfView.swift
//  Notchway
//
//  Created by Igor Marcossi on 13/05/24.
//

import SwiftUI

struct ShelfView: View {
    static let id = "sheld"
    var hovered: Bool
    var full: Bool
    var body: some View {
        let files = Shelf.shared.files
        HStack {
            
            Group {
                
                if files.count > 0 && full {
                    
                    ShelfFilesScrollView(files: files, selectedFiles: Shelf.shared.selectedFiles, selectFile: Shelf.shared.selectFile)
                    
                } else {
                    
                    HStack {
                        ShelfEmptyView(hovered: hovered, centered: full)
                        
                        Spacer()
                        
                        ShelfFilesTargetPreviewView(files: Array(files.prefix(4)))
                    }
                    .padding(.horizontal, 24)
                    
                }
                
            }
            .transition(.scaleAndBlur(anchor: .top))
        }
        .defaultOpenSize(disable: !full)
        .frame(maxWidth: full ? nil : .infinity, maxHeight: full ? nil : .infinity, alignment: .leading)
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

