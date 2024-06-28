//
//  NoteView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/06/24.
//

import SwiftUI
import RichTextKit

struct NoteView: View, Equatable {
    static func == (lhs: NoteView, rhs: NoteView) -> Bool {
        lhs.note.persistentModelID == rhs.note.persistentModelID &&
        lhs.selected == rhs.selected &&
        rhs.width == lhs.width &&
        rhs.prefs == lhs.prefs
    }
    
    var note: Note
    var selected: Bool
    var width: Double
    var prefs: NotesWidgetSettings
    var ns: Namespace.ID
    @State private var text: NSAttributedString
    @State private var showControls = false
    @State private var downScaled = false
    @StateObject var context: RichTextContext
    
    init(note: Note, selected: Bool, width: Double, prefs: NotesWidgetSettings, ns: Namespace.ID, text: NSAttributedString = NSAttributedString(string: ""), context: RichTextContext = RichTextContext()) {
        self.note = note
        self.selected = selected
        self.width = width
        self.prefs = prefs
        self.ns = ns
        let context = RichTextContext()
        context.isEditable = selected
        self._context = .init(wrappedValue: context)
        self._text = .init(initialValue: note.text)
        self._downScaled = .init(initialValue: selected)
    }
    
    var body: some View {
        let cornerRadius: Double = selected ? 13 : 8
        ZStack(alignment: .bottomTrailing) {
            Group {
                RichTextEditor(text: $text, context: context) { config in
                    if let textView = config as? NSTextView {
                        textView.isEditable = selected
                        textView.backgroundColor = .clear
                        textView.enclosingScrollView?.hasVerticalScroller = prefs.showScrollIndicator
                        textView.enclosingScrollView?.additionalSafeAreaInsets = selected ? .init(10) : .zero
                    }
                }
                .focusedValue(\.richTextContext, context)
            }
            .frame(width: width, height: selected ? nil : 100, alignment: .topLeading)
            .matchedGeometryEffect(id: "\(note.persistentModelID)-note-editor", in: ns)
            .scaleEffect(downScaled ? 0.29 : 1, anchor: .topLeading)
            .padding(!selected ? 6 : 0)
            .fadeOnEdges(axis: .vertical, fadeLength: 20, curve: .easeOut, disable: !selected)
            
            if selected {
                RichToolbarView(context: context)
                    .padding(4)
                    .scaleEffect(showControls ? 1 : 0.75, anchor: .bottomTrailing)
                    .opacity(showControls ? 1 : 0)
                    .blur(radius: showControls ? 0 : 24)
            }
        }
        .richTextEditorConfig(.init(isScrollingEnabled: true, isContinuousSpellCheckingEnabled: false))
        .richTextEditorStyle(.init(font: .systemFont(ofSize: 13), fontColor: .white, backgroundColor: .clear))
        .allowsHitTesting(selected)
        .foregroundStyle(.white)
        .frame(maxWidth: selected ? .infinity : 29, maxHeight: selected ? .infinity : 29, alignment: .topLeading)
        .geometryGroup()
        .matchedGeometryEffect(id: "\(note.persistentModelID)-note", in: ns)
        .contentShape(Rectangle())
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .mask {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(.black)
                .matchedGeometryEffect(id: "\(note.persistentModelID)-note-mask", in: ns)
        }
        .background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).fill(.noteBG.shadow(.drop(radius: 16, y: 8)))
                .matchedGeometryEffect(id: "\(note.persistentModelID)-note-bg", in: ns)
        }
        .onAppear {
            withAnimation(NotesWidgetView.switchAnimation) { downScaled.toggle() }
            withAnimation(.spring.delay(0.3)) { showControls = true }
        }
        .transition(.scale(1))
        .zIndex(selected ? 1 : 0)
        .onChangeDebounced(of: text.string, delay: 0.5) { _ in
            note.text = text
            note.updatedAt = Date()
            try? note.modelContext?.save()
        }
        .id(note.persistentModelID)
    }
}

extension View {
    public func cursor(_ cursor: NSCursor) -> some View {
        if #available(macOS 13.0, *) {
            return self.onContinuousHover { phase in
                switch phase {
                case .active(_):
                    guard NSCursor.current != cursor else { return }
                    cursor.push()
                case .ended:
                    NSCursor.pop()
                }
            }
        } else {
            return self.onHover { inside in
                if inside {
                    cursor.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
    }
}
