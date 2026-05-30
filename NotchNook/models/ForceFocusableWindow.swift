//
//  ForceFocusableWindow.swift
//  NotchNook
//
//  Created by Lori Montenegro on 20/08/24.
//

import AppKit

class ForceFocusableWindow: NSPanel {

    /// Called after each successful `makeFirstResponder` change (IME composition excepted).
    /// Parameter: `true` when the panel itself (or nil) is the responder — i.e. no text field is active.
    var firstResponderCb: ((_ isWindowItself: Bool) -> Void)?

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    }

    override func makeFirstResponder(_ responder: NSResponder?) -> Bool {
        let success = super.makeFirstResponder(responder)
        guard success else { return false }
        // IME guard: don't disturb state while text is being composed.
        if let textView = responder as? NSTextView, textView.hasMarkedText() {
            return success
        }
        let isWindowItself = (responder === self) || (responder == nil)
        firstResponderCb?(isWindowItself)
        return success
    }
}
