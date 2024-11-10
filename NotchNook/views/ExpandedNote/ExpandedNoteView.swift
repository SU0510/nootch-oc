//
//  ExpandedNoteView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 03/07/24.
//

import SwiftUI
import RichTextKit

struct ExpandedNoteView: View {
    
    var note: Note
    var isCodeMode: Bool
    
    @Environment(\.expandedNoteManager) private var expandedNoteManager
    @State private var isExporting = false
    
    var body: some View {
        Group {
            if isCodeMode {
                NoteCodeEditor(note: note)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                NoteRichEditor(note: note)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .frame(width: 840, height: 560)
        .padding()
        .toolbar {
            if !isCodeMode {
                ToolbarItemGroup(placement: .principal) {
                    RichToolbarView(context: expandedNoteManager.richTextContext, buttonStyle: .expanded)
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: {
                        isExporting = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .help("Export Note")
                }
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: NoteDocument(note: note),
            contentType: .plainText,
            defaultFilename: "Exported Note"
        ) { result in
            switch result {
                case .success(let url):
                    print("Note exported successfully to \(url)")
                case .failure(let error):
                    print("Failed to export note: \(error.localizedDescription)")
            }
        }
    }
}
