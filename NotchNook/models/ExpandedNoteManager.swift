//
//  ExpandedNoteManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 03/07/24.
//

import SwiftUI

@Observable
class ExpandedNoteManager {
    typealias OpenWindowFn = (_ activeNote: Note, _ displayKitId: UUID) -> ()
    private(set) var activeNote: Note?
    private(set) var windowOrigin: CGPoint? = .zero
    private var buttonsOrigins = [String:CGPoint]()
    
    private var openWindow: OpenWindowFn?
    
    func openNote(_ note: Note?, buttonId: String? = nil, displayKitId: UUID? = nil) {
        if let buttonId {
            windowOrigin = buttonsOrigins[buttonId]
        } else {
            windowOrigin = nil
        }
        activeNote = note
        if let note, let displayKitId {
            openWindow?(note, displayKitId)
        }
    }
    
    func setButtonOrigin(of button: String, to origin: CGPoint) {
        buttonsOrigins[button] = origin
    }
    
    func setOpenWindowFunction(_ function: OpenWindowFn?) {
        openWindow = function
    }
}
