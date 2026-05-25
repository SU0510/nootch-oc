//
//  NotesWidgetView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/06/24.
//

import SwiftUI
import SwiftData
import Combine

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
    // Periodic autosave every 5 seconds to protect against crash data loss.
    private let autosaveTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @State private var autosaveCancellable: AnyCancellable?

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
                NoteView(note: selectedNote, isSelected: true, width: mainNoteWidth, widgetArrPosition: arrayPosition, ns: ns)
                    .id(selectedNote.persistentModelID)
                VStack(alignment: .leading, spacing: Self.spacing) {
                    ForEach(Array(otherNotes.enumerated()), id: \.element.persistentModelID) { i, note in
                        Button {
                            withAnimation(NotesWidgetView.switchAnimation) { selectedNoteId = note.persistentModelID }
                        } label: {
                            NoteView(note: note, isSelected: false, width: mainNoteWidth, widgetArrPosition: i == (otherNotes.count - 1) ? arrayPosition : .middle, ns: ns)
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
            do {
                let existingIcons = Set(notes.map { $0.icon })
                let icons = ["diamond.fill", "triangle.fill", "circle.fill", "app.fill"]
                let neededIcons = icons.filter { !existingIcons.contains($0) }
                
                for icon in neededIcons.prefix(4 - notes.count) {
                    let newNote = Note(icon: icon)
                    modelContext.insert(newNote)
                }
                
                try modelContext.save()
            } catch {
                print("Error creating default notes: \(error)")
            }
        }
        .onExitCommand {
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
        .onReceive(autosaveTimer) { _ in
            do { try modelContext.save() }
            catch { print("[Notes] autosave failed: \(error)") }
        }
    }
}
