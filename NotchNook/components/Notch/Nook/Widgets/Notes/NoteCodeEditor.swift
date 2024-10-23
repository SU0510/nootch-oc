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
    let detector = LanguageDetector()

    @Environment(\.notesWidgetSettings) private var prefs
    @Environment(\.expandedNoteManager) private var expandedNoteManager

    @State private var localCodeText: String = ""
    @State private var localLanguage: CodeEditor.Language = .markdown
    @State private var updateTrigger = UUID()
    
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
        .fadeOnEdges(axis: .vertical, topLeadingFadeLength: 20, bottomTrailingFadeLength: 48, curve: .easeInOut, disable: !prefs.fadeScrollEdges)
        .onChange(of: localCodeText) {
            note.codeText = $1
            localLanguage = detector.detectLanguage(in: $1)
            note.codeLanguage = localLanguage.rawValue
            print("Detected language: \(localLanguage.rawValue)")
        }
        .onAppear {
            localCodeText = note.codeText
            localLanguage = .init(rawValue: note.codeLanguage)
        }
        .onChange(of: expandedNoteManager.isExpanded) { wasExpanded, willBeExpanded in
            if wasExpanded, !willBeExpanded, let codeText = expandedNoteManager.activeNote?.codeText {
                localCodeText = codeText
                note.codeText = localCodeText
                updateTrigger = UUID()
            }
        }
        .id(updateTrigger)
    }
}
