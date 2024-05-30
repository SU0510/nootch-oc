//
//  ShelfView.swift
//  Notchway
//
//  Created by Igor Marcossi on 13/05/24.
//

import SwiftUI
import Defaults

struct ShelfView: View {
    static let id = "sheld"
    
    var hovered: Bool
    var full: Bool
    
    @Default(.shelfSettings) private var shelfSettings
    
    var body: some View {
        let files = Shelf.shared.files
        HStack {
            Group {
                if files.count > 0 {
                    ShelfFilesScrollView(files: files, selectedFiles: Shelf.shared.selectedFiles, selectFile: Shelf.shared.selectFile)
                } else {
                    ShelfEmptyView(hovered: hovered, centered: true)
                }
            }
            .transition(.scaleAndBlur(anchor: .top))
        }
        .frame(shelfSettings.size.screenPtsCGSize, .leading)
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

