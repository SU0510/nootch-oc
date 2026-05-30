//
//  NoteView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/06/24.
//

import SwiftUI
import RichTextKit
import Defaults
import CodeEditor

struct NoteView: View {
    static let smallSize: Double = 29
    static func == (lhs: NoteView, rhs: NoteView) -> Bool {
        lhs.note.id == rhs.note.id &&
        lhs.isSelected == rhs.isSelected &&
        rhs.width == lhs.width &&
        rhs.widgetArrPosition == lhs.widgetArrPosition &&
        rhs.ns == lhs.ns
    }
    
    var note: Note
    var isSelected: Bool
    var width: Double
    var widgetArrPosition: ArrayPosition
    var ns: Namespace.ID
    
    @State private var showControls = false
    @State private var downScaled: Bool
    @State private var hovering = false
        
    @Environment(\.expandedNoteManager) private var expandedNoteManager
    @Environment(\.notchNook) private var notchNook
    @Environment(\.enableTextEditingForWindowWith) private var enableTextEditingForWindowWith
    @Environment(\.updateEditingTextStateFor) private var updateEditingTextStateFor
    @Environment(\.displayKitId) private var displayKitId
    @Environment(\.notesWidgetSettings) private var settings
    
    init(note: Note, isSelected: Bool, width: Double, widgetArrPosition: ArrayPosition, ns: Namespace.ID) {
        self.note = note
        self.isSelected = isSelected
        self.width = width
        self.widgetArrPosition = widgetArrPosition
        self.ns = ns
        self._downScaled = .init(initialValue: isSelected)
    }
    
    var body: some View {
        let isExpanded = expandedNoteManager.isExpanded && isSelected
        let codeMode = note.isCodeMode && settings.codeMode
        ZStack(alignment: .bottomTrailing) {
            Group {
                if isSelected {
                    if codeMode {
                        NoteCodeEditor(note: note)
                    } else {
                        NoteRichEditor(note: note)
                    }
                } else {
                    NoteMiniatureView(note: note, codeMode: codeMode)
                }
            }
            .frame(width: width - (downScaled ? 0 : 8), height: isSelected ? nil : 100, alignment: .topLeading)
            .fixedSize(horizontal: true, vertical: !isSelected)
            .scaleEffect(downScaled ? 0.29 : 1, anchor: .topLeading)
            .padding(downScaled ? 2 : 0)
            .matchedGeometryEffect(id: "\(note.id)-note-editor", in: ns, properties: [.position])
            .opacity(downScaled && !codeMode ? 0.25 : 0.9)
        }
        .onChange(of: expandedNoteManager.isExpanded) { wasExpanded, isExpanded in
            if wasExpanded, !isExpanded {
                doAfter(0.6) {
                    NSApp.setActivationPolicy(.accessory)
                    notchNook.locked = false
                }
                enableTextEditing()
            }
        }
        .allowsHitTesting(isSelected)
        .foregroundStyle(.nonShockingWhite)
        .matchedGeometryEffect(id: "\(note.id)-note", in: ns)
        .frame(maxWidth: isSelected ? .infinity : Self.smallSize, maxHeight: isSelected ? .infinity : Self.smallSize, alignment: .topLeading)
        .modifier(
            ShapeModifier(
                noteId: "\(note.id)",
                hovering: hovering,
                selected: isSelected,
                downScaled: downScaled,
                widgetArrPosition: widgetArrPosition,
                ns: ns
            )
        )
        .overlay(alignment: !isSelected ? .bottomTrailing : .bottomLeading) {
            NoteIconView(noteId: "\(note.id)", icon: note.icon, downScaled: downScaled, ns: ns, color: codeMode ? Color.cyan : .blue)
                    .padding(.trailing, isSelected ? 4 : 0)
        }
        .overlay(alignment: .bottomTrailing) {
            if isSelected {
                HStack(spacing: 3) {
//                    let expandedNoteId = "notes-widget"
//                    RichToolbarButtonView(
//                        icon: "arrow.up.left.and.arrow.down.right",
//                        tooltip: "Expand",
//                        action: {
//                            notchNook.locked = true
//                            expandedNoteManager.openNote(note, buttonId: expandedNoteId, displayKitId: displayKitId, isCodeMode: codeMode)
//                        },
//                        active: false,
//                        buttonStyle: .widget
//                    )
//                    .syncOriginWithExpandedNoteManger(id: expandedNoteId)
                    
                    if settings.codeMode {
                        RichToolbarButtonView(
                            icon: codeMode ? "square.and.pencil" : "curlybraces",
                            tooltip: "Expand",
                            action: {
                                withAnimation(NotesWidgetView.switchAnimation) { note.isCodeMode.toggle() }
                            },
                            active: false,
                            buttonStyle: .widget
                        )
                        .opacity(showControls ? 1 : 0)
                        .blur(radius: showControls ? 0 : 24)
                    }
                
                    if !codeMode {
                        RichToolbarView(context: expandedNoteManager.richTextContext)
                            .transition(.scaleAndBlur)
                    }
                }
                .padding(4)
                .scaleEffect(showControls ? 1 : 0.75, anchor: .bottomTrailing)
                .opacity(showControls ? 1 : 0)
                .blur(radius: showControls ? 0 : 24)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
        }
        .contentShape(Rectangle())
        .geometryGroup()
        .scaleEffect(isExpanded ? 0.5 : 1, anchor: .bottom)
        .blur(radius: isExpanded ? 40 : 0)
        .offset(y: isExpanded ? 200 : 0)
        .background {
            if isExpanded && isSelected {
                NoteExpandedMsgView()
                    .transition(.asymmetric(insertion: .opacity.animation(.easeInOut.delay(0.25)), removal: .opacity))
            }
        }
        .animation(.spring, value: isExpanded)
        .onHover { x in if !isSelected { withAnimation(.easeOut) { hovering = x } } }
        .zIndex(isSelected ? 1 : 0)
        .animation(.spring, value: widgetArrPosition)
//        .clipped()
        .onAppear {
            if isSelected {
                note.updatedAt = Date()
                do { try note.modelContext?.save() }
                catch { print("[Notes] onAppear save failed: \(error)") }
            }
            withAnimation(NotesWidgetView.switchAnimation) { downScaled.toggle() }
            withAnimation(.spring.delay(0.3)) { showControls = true }
            enableTextEditing()
        }
        .onDisappear {
            updateEditingTextStateFor(displayKitId, false)
        }
        .transition(.scale(1))
    }
    
    private func enableTextEditing() {
        enableTextEditingForWindowWith(displayKitId)
    }
}
