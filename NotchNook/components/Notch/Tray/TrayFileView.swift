//
//  TrayFileView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct TrayFileView: View {
    
    let file: TrayFile
    let isSelected: Bool
    var isPreview: Bool = false
    
    @State private var isHovering = false
    
    @Environment(\.tray) private var tray
    
    var body: some View {
        VStack(spacing: 2) {
            TrayFileIconView(file: file)
                .frame(width: 42, height: 42)
                .allowsHitTesting(false)
            
            fileNameView
        }
        .foregroundStyle(.white)
        .padding(6)
        .frame(maxHeight: .infinity)
        .background {
            if !isPreview {
                FileDraggableView(onSelect: {
                    tray.selectFile(file)
                }, onDropCompleted: { success in
                    if !success { return }
                    tray.selectedFiles.forEach { tray.removeFile($0) }
                }, selectedURLs: tray.selectedFiles.map { $0.url }) {
                    TrayFileDragPreviewView(draggedFile: file)
                }
            }
        }
        .background(Color.white.opacity(isSelected ? 0.1 : 0), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(alignment: .topTrailing) {
            VStack {
                if isHovering {
                    Button {
                        tray.removeFile(file)
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
            .frame(20)
            .contentShape(Circle())
            .onHover { x in withAnimation(.smooth(duration: 0.3, extraBounce: 0.15)) { isHovering = x } }

        }
        .transition(.scaleAndBlur)
        .contextMenu {
            Button("Copy") {
                // TODO: implement copying
            }
            Button("Rename") {
                // TODO: implement renaming
            }
        }
    }
    
    var fileNameView: some View {
        VStack(alignment: .leading) {
            Text(file.nameTruncated)
                .font(.caption)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 56, alignment: .center)
                .multilineTextAlignment(.center)
                .allowsHitTesting(false)
        }
    }
}
