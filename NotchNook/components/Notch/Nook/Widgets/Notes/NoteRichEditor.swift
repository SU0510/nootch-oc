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
    var selected: Bool
    var showControls: Bool
    var prefs: NotesWidgetSettings
    @State private var localRichText: NSAttributedString
    @State private var initialRichText: AttributedString
    @StateObject private var richTextContext = RichTextContext()
    
    init(note: Note, selected: Bool, showControls: Bool, prefs: NotesWidgetSettings) {
        self.note = note
        self.selected = selected
        self.showControls = showControls
        self.initialRichText = AttributedString(note.richText)
        self.prefs = prefs
        self._localRichText = .init(initialValue: note.richText)
    }
    
    var body: some View {
        if selected {
            CRichTextEditor(text: $localRichText, context: richTextContext) { config in
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
            .richTextEditorStyle(.init(font: .systemFont(ofSize: 13), fontColor: .white, backgroundColor: .clear))
            .focusedValue(\.richTextContext, richTextContext)
            .fadeOnEdges(axis: .vertical, topLeadingFadeLength: 20, bottomTrailingFadeLength: 40, curve: .easeInOut, disable: !selected || !prefs.fadeScrollEdges)
            .overlay(alignment: .bottomTrailing) {
                if selected {
                    RichToolbarView(note: note, context: richTextContext)
                        .padding(4)
                        .scaleEffect(showControls ? 1 : 0.75, anchor: .bottomTrailing)
                        .opacity(showControls ? 1 : 0)
                        .blur(radius: showControls ? 0 : 24)
                }
            }
            .onReceive(richTextContext.objectWillChange) { _ in
                note.richText = localRichText
                note.updatedAt = Date()
            }
        } else {
            FakeRichEditor(str: initialRichText)
        }
    }
}



