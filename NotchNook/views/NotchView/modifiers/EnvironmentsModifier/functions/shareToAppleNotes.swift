//
//  shareToAppleNotes.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI
import AppKit


extension NotchView.EnvironmentsModifier {

}
//func shareToAppleNotes(attributedString: NSAttributedString) {
//    let pasteboard = NSPasteboard.general
//    pasteboard.clearContents()
//    pasteboard.writeObjects([attributedString])
//
//    let script = """
//tell application "Notes"
//    make new note with properties {name:"Note from App", body:(the clipboard as text)}
//end tell
//"""
//
//    var error: NSDictionary?
//    if let scriptObject = NSAppleScript(source: script) {
//        scriptObject.executeAndReturnError(&error)
//        if let error = error {
//            print("AppleScript Error: \(error)")
//        }
//    }
//}
