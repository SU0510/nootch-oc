//
//  ForceFocusableWindow.swift
//  NotchNook
//
//  Created by Lori Montenegro on 20/08/24.
//

import AppKit

class ForceFocusableWindow: NSWindow, NSWindowDelegate {
    var becomeKeyCb: (() -> ())?
    var resignedKeyCb: (() -> ())?
    var firstResponderCb: ((_ isTheWindow: Bool) -> ())?
    var canThisWindowBecomeKeyWindow = false
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.delegate = self
    }
    
    func enableTextEditing() {
        canThisWindowBecomeKeyWindow = true
        makeKeyAndOrderFront(nil)
    }
    
    override var canBecomeKey: Bool {
        canThisWindowBecomeKeyWindow
    }
    
    override func makeFirstResponder(_ responder: NSResponder?) -> Bool {
        let success = super.makeFirstResponder(responder)

        if success {
            // Only trigger callback if not during IME composition
            if let textView = responder as? NSTextView, textView.hasMarkedText() {
                // Don't change state during IME composition
                return success
            }
            firstResponderCb?(responder is NSWindow || responder == nil)
        }
        return success
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        becomeKeyCb?()
    }
    
    func windowDidResignKey(_ notification: Notification) {
        resignedKeyCb?()
    }
}
