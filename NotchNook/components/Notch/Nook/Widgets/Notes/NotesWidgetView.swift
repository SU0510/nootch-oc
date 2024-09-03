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
    var internalPadding: Double
    
    @Environment(\.notesWidgetSettings) private var prefs
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    @State private var selectedNoteId: PersistentIdentifier?
    @Environment(\.modelContext) private var modelContext
    @Namespace private var ns

    private var selectedNote: Note? { notes.first(where: { $0.persistentModelID == selectedNoteId }) }
    private var mainNoteWidth: Double {
        let widgetWidth = prefs.size.width.screenPoints
        let internalTotalPadding = (internalPadding * (arrayPosition == .single ? 0 : arrayPosition == .middle ? 2 : 1))
        let hStackSpacing = Self.spacing
        let smallNotesWidth = NoteView.smallSize
        return (widgetWidth - internalTotalPadding - hStackSpacing - smallNotesWidth)
    }
    
    var otherNotes: [Note] { notes.filter { $0.id != selectedNoteId }.sorted(by: { $0.updatedAt > $1.updatedAt }) }
    var otherNotesIds: [PersistentIdentifier] { otherNotes.map { $0.persistentModelID } }
    var body: some View {
        
        HStack(alignment: .top, spacing: Self.spacing) {
            if let selectedNote {
                NoteView(note: selectedNote, selected: true, width: mainNoteWidth, widgetArrPosition: arrayPosition, codeMode: prefs.codeMode, ns: ns)
                    .id(selectedNote.persistentModelID)
                VStack(alignment: .leading, spacing: Self.spacing) {
                    ForEach(Array(otherNotes.enumerated()), id: \.element) { i, note in
                        Button {
                            withAnimation(NotesWidgetView.switchAnimation) { selectedNoteId = note.persistentModelID }
                        } label: {
                            NoteView(note: note, selected: false, width: mainNoteWidth, widgetArrPosition: i == (otherNotes.count - 1) ? arrayPosition : .middle, codeMode: prefs.codeMode, ns: ns)
                        }
                        .buttonStyle(ShrinkOnClick(minSize: 0.925))
                    }
                }
            }
        }
        .animation(.spring, value: otherNotesIds)
        .paddingDependingOnArrPos(arrayPosition: arrayPosition, padding: internalPadding)
        .frame(prefs.size.screenPtsCGSize, .leading)
        .onChange(of: notes.count, initial: true) { _, _ in
            selectedNoteId = notes.first?.persistentModelID
        }
        .onAppear {
//            try? modelContext.delete(model: Note.self)
            if notes.count < 4 {
                let icons = ["diamond.fill", "triangle.fill", "circle.fill", "app.fill"]
                let notesToCreate = 4 - notes.count
                Array(Array(repeating: 0, count: notesToCreate).enumerated()).forEach { i, _ in
                    let newNote = Note(icon: icons[i])
                    modelContext.insert(newNote)
                }
            }
        }
    }
}

//#Preview {
//    NotesWidgetView()
//}
