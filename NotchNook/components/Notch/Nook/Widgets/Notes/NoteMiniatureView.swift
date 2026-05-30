//
//  FakeRichEditor.swift
//  NotchNook
//
//  Created by Igor Marcossi on 02/07/24.
//

import SwiftUI
import CodeEditor

struct NoteMiniatureView: View {
    
    var note: Note
    var codeMode: Bool
    
    @State private var fontSize: CGFloat = 10

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if codeMode {
                CodeEditor(
                    source: .constant(note.codeText),
                    language: CodeEditor.Language(rawValue: note.codeLanguage),
                    theme: .ocean,
                    fontSize: $fontSize,
                    inset: CGSize(width: 4, height: 5),
                    backgroundColor: NSColor(Color.noteBG),
                    bottomOverscroll: 16
                )
                .frame(height: 100, alignment: .topLeading)
            } else {
                Text(AttributedString(note.richText))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(EdgeInsets(top: 13, leading: 13, bottom: 40, trailing: 13))
                    .foregroundStyle(.primary)
            }
                
        }
        .coordinateSpace(name: "scroll")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipped()
        .scrollDisabled(true)
        .allowsHitTesting(false)
    }
}
