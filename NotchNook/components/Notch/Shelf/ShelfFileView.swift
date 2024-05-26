//
//  ShelfFileView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct ShelfFileView: View, Equatable {
    static func == (lhs: ShelfFileView, rhs: ShelfFileView) -> Bool {
        lhs.file == rhs.file && lhs.isSelected == rhs.isSelected
    }
    
    let file: ShelfFile
    let isSelected: Bool
    var preview: Bool = false
    
    @State private var hovering = false
    
    var body: some View {
        VStack(spacing: 2) {
            file.iconView()
                .frame(width: 42, height: 42)
                .allowsHitTesting(false)
            
            VStack(alignment: .leading) {
                Text(file.nameTruncated).font(.caption)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 56, alignment: .center)
                    .multilineTextAlignment(.center)
                    .allowsHitTesting(false)
            }
            
        }
        .foregroundStyle(.white)
        .padding(6)
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .onHover { x in withAnimation(.smooth(duration: 0.3, extraBounce: 0.15)) { hovering = x } }
        .background {
            if !preview {
                FileDraggableView(onSelect: {
                    Shelf.shared.selectFile(file)
                }, onDropCompleted: { l in
                    Shelf.shared.selectedFiles.forEach { $0.remove() }
                }, selectedURLs: Shelf.shared.selectedFiles.map { $0.url }) {
                    ShelfFileDragPreviewView(draggedFile: file)
                }
            }
        }
        .background(Color.white.opacity(isSelected ? 0.1 : 0), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if hovering {
                Button {
                    file.remove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.gray)
                }
                .buttonStyle(ShrinkOnClick())
                .transition(.scale)
                .offset(x: 2, y: -2)
            }
        }
        .transition(.scaleAndBlur)
    }
}
