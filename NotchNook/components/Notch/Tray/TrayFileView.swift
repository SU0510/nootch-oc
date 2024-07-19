//
//  TrayFileView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct TrayFileView: View {
    
    @ObservedObject var file: TrayFile
    let isSelected: Bool
    var isPreview: Bool = false
    
    @State private var isHovering = false
    @State private var isEditing: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    @Environment(\.tray) private var tray
    
    var body: some View {
        VStack(spacing: 2) {
            TrayFileIconView(file: file)
                .frame(width: 42, height: 42)
            
            fileNameView
        }
        .foregroundStyle(.white)
        .padding(6)
        .frame(maxHeight: .infinity)
        .background {
            if !isPreview {
                FileDraggableView(onSelect: {
                    tray.selectFile(file)
                }, onDropCompleted: { didMoveFile in
                    if !didMoveFile { return }
                    tray.selectedFiles.forEach { tray.removeFile($0) }
                }, selectedURLs: tray.selectedFiles.map { $0.url }) {
                    TrayFileDragPreviewView(draggedFile: file)
                }
            }
        }
        .background(Color.white.opacity(isSelected ? 0.1 : 0), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(alignment: .topTrailing) { removeButton }
        .transition(.scaleAndBlur)
        .contextMenu {
            Button("Copy") {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.writeObjects([file.url as NSPasteboardWriting])
            }
            .keyboardShortcut("c", modifiers: .command)
            Button("Rename") {
                doAfter {
                    isEditing = true
                    isTextFieldFocused = true
                }
            }
        }
        .onTapGesture {
            doAfter { if isEditing && !isHovering { isEditing = false } }
        }
    }
    
    var fileNameView: some View {
        VStack(alignment: .leading) {
            if isEditing {
                TextField("", text: $file.name, onCommit: {
                    isEditing = false
                })
                .textFieldStyle(EditingTextFieldStyle())
                .focused($isTextFieldFocused)
            } else {
                Text(file.nameTruncated)
                    .allowsHitTesting(true)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(2)
                    .background(
                        RoundedRectangle(cornerRadius: 4).fill(isSelected ? Color.blue : Color.clear)
                    )
                    .onTapGesture {
                        doAfter {
                            isEditing = true
                            isTextFieldFocused = true
                        }
                    }
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 56, alignment: .center)
            }
        }
        .font(.caption)
    }
    
    var removeButton: some View {
        VStack {
            if isHovering {
                Button {
                    doAfter { tray.removeFile(file) }
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
}

struct EditingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.caption)
            .frame(width: 56, alignment: .center)
            .onAppear {
                doAfter {
                    if let textField = NSApp.keyWindow?.firstResponder as? NSTextField {
                        textField.selectText(nil)
                        if let dotIndex = textField.stringValue.lastIndex(of: ".") {
                            let range = NSRange(location: 0, length: textField.stringValue.distance(from: textField.stringValue.startIndex, to: dotIndex))
                            textField.currentEditor()?.selectedRange = range
                        }
                    }
                }
            }
    }
}
