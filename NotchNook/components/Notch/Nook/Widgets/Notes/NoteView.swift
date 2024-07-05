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
        lhs.selected == rhs.selected &&
        rhs.width == lhs.width &&
        rhs.widgetArrPosition == lhs.widgetArrPosition &&
        rhs.prefs == lhs.prefs &&
        rhs.ns == lhs.ns
    }
    
    var note: Note
    var selected: Bool
    var width: Double
    var widgetArrPosition: ArrayPosition
    var prefs: NotesWidgetSettings
    var ns: Namespace.ID
    @State private var showControls = false
    @State private var downScaled: Bool
    @State private var hovering = false
    @Environment(\.expandedNoteManager) private var expandedNoteManager
    @Environment(\.notchNook) private var notchNook
    
    init(note: Note, selected: Bool, width: Double, widgetArrPosition: ArrayPosition, prefs: NotesWidgetSettings, ns: Namespace.ID) {
        self.note = note
        self.selected = selected
        self.width = width
        self.widgetArrPosition = widgetArrPosition
        self.prefs = prefs
        self.ns = ns
        self._downScaled = .init(initialValue: selected)
    }
    
    var body: some View {
        let expanded = expandedNoteManager.activeNote?.id == note.id
        ZStack(alignment: .bottomTrailing) {
            Group {
                if prefs.codeMode {
                    NoteCodeEditor(note: note, selected: selected, showControls: showControls, prefs: prefs)
                } else {
                    NoteRichEditor(note: note, selected: selected, showControls: showControls, prefs: prefs)
                }
            }
            .frame(width: width - (downScaled ? 0 : 8), height: selected ? nil : 100, alignment: .topLeading)
            .fixedSize(horizontal: true, vertical: !selected)
            .scaleEffect(downScaled ? 0.29 : 1, anchor: .topLeading)
            .padding(downScaled ? 2 : 0)
            .matchedGeometryEffect(id: "\(note.id)-note-editor", in: ns, properties: [.position])
            .opacity(downScaled ? 0.25 : 0.9)
        }
        .onChange(of: expanded) { old, new in
            if old, !new {
                doAfter(0.6) {
                    NSApp.setActivationPolicy(.accessory)
                    notchNook.locked = false
                }
            }
        }
        .allowsHitTesting(selected)
        .foregroundStyle(.white)
        .matchedGeometryEffect(id: "\(note.id)-note", in: ns)
        .frame(maxWidth: selected ? .infinity : Self.smallSize, maxHeight: selected ? .infinity : Self.smallSize, alignment: .topLeading)
        .modifier(
            ShapeModifier(
                noteId: "\(note.id)",
                hovering: hovering,
                selected: selected,
                downScaled: downScaled,
                widgetArrPosition: widgetArrPosition,
                ns: ns
            )
        )
        .overlay(alignment: !selected ? .bottomTrailing : .bottomLeading) {
            NoteIconView(noteId: "\(note.id)", icon: note.icon, downScaled: downScaled, ns: ns)
        }
        .contentShape(Rectangle())
        .geometryGroup()
        .scaleEffect(expanded ? 0.5 : 1, anchor: .bottom)
        .blur(radius: expanded ? 40 : 0)
        .offset(y: expanded ? 200 : 0)
        .background {
            if expanded {
                NoteExpandedMsgView()
                    .transition(.asymmetric(insertion: .opacity.animation(.easeInOut.delay(0.25)), removal: .opacity))
            }
        }
        .animation(.spring, value: expanded)
        .onHover { x in if !selected { withAnimation(.easeOut) { hovering = x } } }
        .zIndex(selected ? 1 : 0)
        .animation(.spring, value: widgetArrPosition)
        .onAppear {
            if selected {
                note.updatedAt = Date()
                try? note.modelContext?.save()
            }
            withAnimation(NotesWidgetView.switchAnimation) { downScaled.toggle() }
            withAnimation(.spring.delay(0.3)) { showControls = true }
        }
        .transition(.scale(1))
    }
}
