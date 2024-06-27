//
//  NotesWidgetView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/06/24.
//

import SwiftUI
import SwiftData

struct NotesWidgetView: View {
    var prefs: NotesWidgetSettings
    @Query private var notes: [Note]
    @State private var selectedNoteId: PersistentIdentifier?
    @Environment(\.modelContext) private var modelContext
    @Namespace private var ns

    private var selectedNote: Note? { notes.first(where: { $0.id == selectedNoteId }) }
    
    var body: some View {
        
        HStack(alignment: .top, spacing: 6) {
            if let selectedNote {
                NoteView(note: selectedNote, selected: true, ns: ns)
            }
//            VStack(alignment: .leading, spacing: 6) {
//                ForEach(notes.filter { $0.id != selectedNoteId }) { note in
//                    NoteView(note: note, selected: false, ns: ns)
//                }
//            }
        }
        .onChange(of: notes.count, initial: true) { _, _ in
            selectedNoteId = notes.first?.id
        }
        .onAppear {
            if notes.count < 4 {
                let notesToCreate = 4 - notes.count
                Array(repeating: 0, count: notesToCreate).forEach { _ in
                    let newNote = Note()
                    modelContext.insert(newNote)
                }
            }
        }
    }
}

//#Preview {
//    NotesWidgetView()
//}
