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

    @State private var isHovering = false
    @State private var fileName: String
    @FocusState private var isTextFieldFocused: Bool
    
    @Environment(\.tray) private var tray
    @Environment(\.enableTextEditingForWindowWith) private var enableTextEditingForWindowWith
    @Environment(\.updateEditingTextStateFor) private var updateEditingTextStateFor
    @Environment(\.displayKitId) private var displayKitId
    @Environment(\.makeKeyWindow) private var makeKeyWindow
    
    var selectedFiles: [TrayFile] {
        tray.selectedFiles.isEmpty ? [file] : tray.selectedFiles
    }
    
    init(file: TrayFile, isSelected: Bool, isPreview: Bool = false) {
        self.file = file
        self.fileName = file.name
        self.isSelected = isSelected
    }
    
    var body: some View {
        VStack {
            TrayFileIconView(file: file)
                .frame(width: 40, height: 40)
            
            fileNameView
        }
        .foregroundStyle(.white)
        .padding(6)
        .frame(maxHeight: .infinity, alignment: .top)
        .background {
            FileDraggableView(
                onSelect: {
                    doAfter(0.04) {
                        tray.selectFile(file)
                    }
                },
                onDropCompleted: { didMoveFile in
                    if !didMoveFile { return }
                    doAfter {
                        selectedFiles.forEach {
                            tray.removeFile($0)
                        }
                    }
                },
                selectedURLs: selectedFiles.map { $0.url }
            ) {
                TrayFileDragPreviewView(draggedFile: file)
            }
        }
        .background(Color.white.opacity(isSelected ? 0.1 : 0), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(alignment: .topTrailing) {
            removeButton
                .zIndex(1)
        }
        .transition(.scaleAndBlur)
        .contextMenu {
            Button(String(localized: "Copy")) {
                doAfter {
                    tray.copySelectedFilesToClipboard()
                }
            }.keyboardShortcut("c", modifiers: .command)
            
            Button(String(localized: "Rename")) {
                doAfter {
                    tray.editingFile = (file, file.name)
                    enableTextEditing()
                }
            }
            
            Button(String(localized: "Remove from tray")) {
                doAfter { tray.removeSelectedFiles(currentFile: file) }
            }
            
            Button(String(localized: "Send via AirDrop")) {
                doAfter {
                    tray.airdropSelectedFiles()
                }
            }
        }
        .onTapGesture(count: 2) {
            doAfter {
                if let event = NSApp.currentEvent, event.type == .leftMouseUp, event.clickCount == 2 {
                    tray.openFile(file)
                }
            }
        }
    }
    
    var fileNameView: some View {
        VStack(alignment: .leading) {
            if let editingFile = tray.editingFile, editingFile.file == file {
                MultilineTextField(text: Binding(
                    get: { tray.editingFile?.newName ?? "" },
                    set: { tray.editingFile?.newName = $0 }
                ))
                .frame(width: 56)
                .onAppear {
                    doAfter { tray.editingFile?.newName = file.name }
                    enableTextEditing()
                }
                .onDisappear {
                    updateEditingTextStateFor(displayKitId, false)
                }
            } else {
                NonHyphenatingText(text: file.nameTruncated)
                    .frame(width: 56, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 3).fill(isSelected ? Color.blue : Color.clear)
                    )
                    .onTapGesture {
                        doAfter {
                            if isSelected {
                                tray.editingFile = (file, file.name)
                                enableTextEditing()
                            }
                        }
                    }
                    .id(file.id)
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
        .allowsHitTesting(true)
    }
    
    private func enableTextEditing() {
        doAfter (0.1) {
            enableTextEditingForWindowWith(displayKitId)
            makeKeyWindow()
            isTextFieldFocused = true
        }
    }
}
