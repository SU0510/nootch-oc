//
//  NoteCodeEditor.swift
//  NotchNook
//
//  Created by Igor Marcossi on 02/07/24.
//

import SwiftUI
import CodeEditor

struct NoteCodeEditor: View {
    var note: Note
    var selected: Bool
    var showControls: Bool

    @Environment(\.notesWidgetSettings) private var prefs
    @State private var localCodeText: String = ""
    @State private var localLanguage: CodeEditor.Language = .markdown
    
    var body: some View {
        CodeEditor(
            source: $localCodeText,
            language: localLanguage,
            theme: .ocean,
            inset: CGSize(width: 8, height: 10),
            backgroundColor: NSColor(Color.noteBG),
            bottomOverscroll: 32,
            hasVerticalScroller: prefs.showScrollIndicator
        )
        .fadeOnEdges(axis: .vertical, topLeadingFadeLength: 20, bottomTrailingFadeLength: 48, curve: .easeInOut, disable: !selected || !prefs.fadeScrollEdges)
        .onChange(of: localCodeText) { note.codeText = $1 }
        .onAppear {
            localCodeText = note.codeText
            localLanguage = .init(rawValue: note.codeLanguage)
        }
    }
}
