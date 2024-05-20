//
//  ShelfFileView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct ShelfFileView: View, Equatable {
    let file: ShelfFile
    let isSelected: Bool
    var preview: Bool = false
    var body: some View {
        HStack(spacing: 6) {
            file.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 42, height: 42)
            
            Text(file.nameTruncated).font(.caption)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 56, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(.white)
        .padding(.all, 6)
        .background(Color.white.opacity(isSelected ? 0.1 : 0), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
//        .onDrag {
//            return NSItemProvider(item: file.url as NSSecureCoding, typeIdentifier: UTType.fileURL.identifier)
//        }
//        .onLongPressGesture(minimumDuration: 0, maximumDistance: 0, perform: { Shelf.shared.selectFile(file) }, onPressingChanged: { pressing in })
        .overlay {
            if !preview {
                FileDraggableView(onSelect: {
                    Shelf.shared.selectFile(file)
                }, selectedURLs: Shelf.shared.selectedFiles.map { $0.url }) {
                    ShelfFileDragPreviewView(draggedFile: file)
                }
            }
        }
        .transition(.scaleAndBlur)
    }
}
