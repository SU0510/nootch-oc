//
//  NoteRichEditor.swift
//  NotchNook
//
//  Created by Igor Marcossi on 02/07/24.
//

import SwiftUI
import RichTextKit

struct NoteRichEditor: View {
    
    var note: Note
    
    @Environment(\.notesWidgetSettings) private var prefs
    @Environment(\.expandedNoteManager) private var expandedNoteManager
    
    @State private var localRichText: NSAttributedString
    @State private var updateTrigger = UUID()
        
    init(note: Note) {
        self.note = note
        self._localRichText = .init(initialValue: note.richText)
    }
    
    var body: some View {
        CRichTextEditor(
            text: Binding(
                get: { localRichText },
                set: { newValue in
                    localRichText = newValue
                    note.richText = newValue
                }
            ),
            context: expandedNoteManager.richTextContext
        ) { config in
            if let textView = config as? NSTextView {
                textView.backgroundColor = .clear
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakStrategy = .pushOut
                textView.defaultParagraphStyle = paragraphStyle
                textView.enclosingScrollView?.hasVerticalScroller = prefs.showScrollIndicator
                textView.enclosingScrollView?.additionalSafeAreaInsets = NSEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
            }
        }
        .richTextEditorConfig(.init(isScrollingEnabled: true, isContinuousSpellCheckingEnabled: false))
        .richTextEditorStyle(.init(font: .systemFont(ofSize: 13), fontColor: .nonShockingWhite, backgroundColor: .clear))
        .fadeOnEdges(axis: .vertical, topLeadingFadeLength: 20, bottomTrailingFadeLength: 40, curve: .easeInOut, disable: !prefs.fadeScrollEdges)
        .onReceive(expandedNoteManager.richTextContext.objectWillChange) {
            // Only assign if content actually changed to avoid triggering Note.willSet
            // (which stamps updatedAt) and the resulting re-layout cascade on every keystroke.
            if localRichText != note.richText {
                note.richText = localRichText
            }
        }
        .onChange(of: expandedNoteManager.isExpanded) { wasExpanded, willBeExpanded in
            if wasExpanded, !willBeExpanded, let richText = expandedNoteManager.activeNote?.richText {
                localRichText = richText
                note.richText = localRichText
                updateTrigger = UUID()
            }
        }
        .id(updateTrigger)
        .background(Color.noteBG)
    }
}
