//
//  NoteDocument.swift
//  NotchNook
//
//  Created by Lori Montenegro on 11/10/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct NoteDocument: FileDocument {
    // Snapshot of the Note's serializable contents captured on the main actor
    // at construction time, so fileWrapper(configuration:) never touches the
    // SwiftData @Model across actor boundaries.
    private struct NoteSnapshot: Sendable {
        let plainText: String
    }

    private let snapshot: NoteSnapshot

    static var readableContentTypes: [UTType] { [.plainText] }

    /// Called from SwiftUI (main actor). Reads Note properties here, on the
    /// context-owning actor, before the FileDocument crosses to the exporter.
    init(note: Note) {
        self.snapshot = NoteSnapshot(plainText: note.richText.string)
    }

    init(configuration: ReadConfiguration) throws {
        fatalError("Import not supported")
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = snapshot.plainText.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
