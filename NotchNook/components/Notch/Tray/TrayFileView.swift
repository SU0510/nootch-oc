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
    @State private var isEditing: Bool = false
    @State private var isTextFieldFocused: Bool = false
    @State private var fileName: String = ""

    @Environment(\.tray) private var tray
//    @EnvironmentObject var pasteboard: NSPasteboard
    
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
        .overlay(alignment: .topTrailing) { removeButton }
        .transition(.scaleAndBlur)
        .contextMenu {
            Button("Copy") {
                // TODO: implement copying file to clipboard
//                doAfter { pasteboard.string = file.url.absoluteString }
            }
            Button("Rename") {
                doAfter { isEditing = true }
            }
        }
        .onTapGesture {
            doAfter { if isEditing && !isHovering { isEditing = false } }
        }
    }
    
    var fileNameView: some View {
        VStack(alignment: .leading) {
            if isEditing {
                TextField("", text: $fileName, onCommit: {
                    file.rename(to: fileName)
                    isEditing = false
                })
                .textFieldStyle(EditingTextFieldStyle())
                .onAppear() {
                    fileName = file.name
                }
            } else {
                Text(file.nameTruncated)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .allowsHitTesting(false)
                    .padding(2)
                    .background(
                        RoundedRectangle(cornerRadius: 4).fill(isSelected ? Color.blue : Color.clear)
                    )
                    .onTapGesture {
                        doAfter {
                            isEditing = true
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
                    //TODO: fix this selection which is not working (the name without the extension should be selected every time the edition starts)
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
