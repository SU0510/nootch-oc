//
//  ForceFocusableWindow.swift
//  NotchNook
//
//  Created by Lori Montenegro on 20/08/24.
//

import AppKit

class ForceFocusableWindow: NSPanel {

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    }

    override func makeFirstResponder(_ responder: NSResponder?) -> Bool {
        let success = super.makeFirstResponder(responder)
        // Guard IME composition: don't disturb state while text is being composed.
        if success, let textView = responder as? NSTextView, textView.hasMarkedText() {
            return success
        }
        return success
    }
}
