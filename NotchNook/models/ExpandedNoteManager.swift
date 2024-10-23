//
//  ExpandedNoteManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 03/07/24.
//

import SwiftUI
import RichTextKit

@Observable
class ExpandedNoteManager {
    typealias OpenWindowFn = (_ activeNote: Note, _ displayKitId: UUID, _ isCodeMode: Bool) -> ()
    private(set) var activeNote: Note?
    private(set) var isExpanded: Bool = false
    private(set) var windowOrigin: CGPoint? = .zero
    var richTextContext = RichTextContext()
    private var buttonsOrigins = [String:CGPoint]()
    
    private var openWindow: OpenWindowFn?
    
    func openNote(_ note: Note?, buttonId: String? = nil, displayKitId: UUID? = nil, isCodeMode: Bool = false) {
        if let buttonId {
            windowOrigin = buttonsOrigins[buttonId]
        } else {
            windowOrigin = nil
        }
        activeNote = note
        if let note, let displayKitId {
            openWindow?(note, displayKitId, isCodeMode)
        }
        isExpanded = true
    }
    
    func closeNote() {
        isExpanded = false
    }
    
    func setButtonOrigin(of button: String, to origin: CGPoint) {
        buttonsOrigins[button] = origin
    }
    
    func setOpenWindowFunction(_ function: OpenWindowFn?) {
        openWindow = function
    }
}
