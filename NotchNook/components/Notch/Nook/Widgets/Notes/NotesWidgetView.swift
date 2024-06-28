//
//  NotesWidgetView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/06/24.
//

import SwiftUI
import SwiftData

struct NotesWidgetView: View {
    static let switchAnimation: Animation = .smooth(duration: 0.45, extraBounce: 0.175)
//    var arrayPosition: ArrayPosition
    var prefs: NotesWidgetSettings
    @Query private var notes: [Note]
    @State private var selectedNoteId: PersistentIdentifier?
    @Environment(\.modelContext) private var modelContext
    @Namespace private var ns

    private var selectedNote: Note? { notes.first(where: { $0.persistentModelID == selectedNoteId }) }
    
    var body: some View {
        
        HStack(alignment: .top, spacing: 6) {
            if let selectedNote {
                NoteView(note: selectedNote, selected: true, width: prefs.size.width.screenPoints, prefs: prefs, ns: ns)
                    .id(selectedNote.persistentModelID)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(notes.filter { $0.id != selectedNoteId }.sorted(by: { $0.updatedAt < $1.updatedAt })) { note in
                        Button {
                            withAnimation(NotesWidgetView.switchAnimation) { selectedNoteId = note.persistentModelID }
                        } label: {
                            NoteView(note: note, selected: false, width: prefs.size.width.screenPoints, prefs: prefs, ns: ns)
                        }
                        .buttonStyle(ShrinkOnClick(minSize: 0.925))
                    }
                }
            }
        }
        .onChange(of: notes.count, initial: true) { _, _ in
            selectedNoteId = notes.first?.persistentModelID
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
