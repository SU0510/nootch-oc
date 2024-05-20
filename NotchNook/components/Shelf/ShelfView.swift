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
            
            if files.count <= 0 {
                
                ShelfEmptyView(hovered: hovered)
                    .padding(.horizontal, 16)
                
            } else {
                
                GeometryReader { geo in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(Array(files).sorted(by: { $0.addedAt.timeIntervalSince1970 > $1.addedAt.timeIntervalSince1970 })) { file in
                                ShelfFileView(file: file, isSelected: Shelf.shared.selectedFiles.contains(file))
                            }
                        }
                        .padding(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .frame(minWidth: geo.size.width, maxHeight: .infinity, alignment: .leading)
                        .background { Color.black.opacity(0.001).onTapGesture { Shelf.shared.selectFile(nil) } }
                    }
                }
                .transition(.scaleAndBlur)
                
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: full ? 32 : 28, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: full ? 32 : 28, style: .continuous)
                .stroke(
                    (hovered ? Color.blue : Color.white).opacity(hovered ? 0.5 : 0.1),
                    style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [6, 12])
                )
        }
        .geometryGroup()
        .animation(.easeOut(duration: 0.2), value: hovered)
    }
}

