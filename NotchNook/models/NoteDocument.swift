//
//  NoteDocument.swift
//  NotchNook
//
//  Created by Lori Montenegro on 11/10/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct NoteDocument: FileDocument, @unchecked Sendable {
    var note: Note
    
    static var readableContentTypes: [UTType] { [.plainText] }
    
    init(note: Note) {
        self.note = note
    }
    
    init(configuration: ReadConfiguration) throws {
        fatalError("Import not supported")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = note.exportToTXT() else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
