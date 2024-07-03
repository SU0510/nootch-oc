//
//  ExpandedNoteManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 03/07/24.
//

import SwiftUI

@Observable
class ExpandedNoteManager {
    var activeNote: Note? {
        didSet {
            if let activeNote {
                openWindow?(activeNote)
            }
        }
    }
    var openWindow: ((_ activeNote: Note) -> ())?
}
