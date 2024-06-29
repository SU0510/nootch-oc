//
//  NotesWidgetView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/06/24.
//

import SwiftUI
import SwiftData

struct NotesWidgetView: View {
    static let spacing: Double = 6
    static let switchAnimation: Animation = .smooth(duration: 0.45, extraBounce: 0.175)
    var arrayPosition: ArrayPosition
    var nookPrefs: NookSettings
    var prefs: NotesWidgetSettings
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    @State private var selectedNoteId: PersistentIdentifier?
    @Environment(\.modelContext) private var modelContext
    @Namespace private var ns

    private var selectedNote: Note? { notes.first(where: { $0.persistentModelID == selectedNoteId }) }
    private var mainNoteWidth: Double { prefs.size.width.screenPoints - (nookPrefs.widgetsPadding * 2) - Self.spacing - NoteView.smallSize }
    
    var otherNotes: [Note] { notes.filter { $0.id != selectedNoteId }.sorted(by: { $0.updatedAt > $1.updatedAt }) }
    var otherNotesIds: [PersistentIdentifier] { otherNotes.map { $0.persistentModelID } }
    var body: some View {
        
        HStack(alignment: .top, spacing: Self.spacing) {
            if let selectedNote {
                NoteView(note: selectedNote, selected: true, width: mainNoteWidth, widgetArrPosition: arrayPosition, prefs: prefs, ns: ns)
                    .id(selectedNote.persistentModelID)
                VStack(alignment: .leading, spacing: Self.spacing) {
                    ForEach(Array(otherNotes.enumerated()), id: \.element) { i, note in
                        Button {
                            withAnimation(NotesWidgetView.switchAnimation) { selectedNoteId = note.persistentModelID }
                        } label: {
                            NoteView(note: note, selected: false, width: mainNoteWidth, widgetArrPosition: i == (otherNotes.count - 1) ? arrayPosition : .middle, prefs: prefs, ns: ns)
                        }
                        .buttonStyle(ShrinkOnClick(minSize: 0.925))
                    }
                }
            }
        }
        .animation(.spring, value: otherNotesIds)
        .paddingDependingOnArrPos(arrayPosition: arrayPosition, padding: nookPrefs.widgetsPadding)
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
