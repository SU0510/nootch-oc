//
//  ForceFocusableWindow.swift
//  NotchNook
//
//  Created by Lori Montenegro on 20/08/24.
//

import AppKit

/// Borderless `.nonactivatingPanel` host for the notch UI.
///
/// `NSPanel` returns `canBecomeKey = false` by default when the style mask is
/// borderless / nonactivating — which means `TextField`s inside the SwiftUI
/// hierarchy never receive keystrokes, the kb-lock indicator never lights up,
/// and unhover-close stays armed because `isEditingText` never flips. We force
/// `canBecomeKey = true` so the panel can host text input, while `canBecomeMain
/// = false` and the `.nonactivatingPanel` style keep app activation in the
/// previously-frontmost app — typing here never steals focus from Code/Mail/etc.
class ForceFocusableWindow: NSPanel {

    /// Fired after each successful `makeFirstResponder` change (IME composition excepted),
    /// with the new responder. Lets the caller distinguish "a text editor is active"
    /// (field editor / NSTextView / NSTextField) from "any other responder" (the
    /// NSHostingView itself, a button, the panel). AppKit installs an initial responder
    /// on open that is typically the contentView (NSHostingView), not the panel — so a
    /// `!= self` check is NOT enough to mean "user is typing".
    var firstResponderCb: ((_ responder: NSResponder?) -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        self.isFloatingPanel = true
    }

    override func makeFirstResponder(_ responder: NSResponder?) -> Bool {
        let success = super.makeFirstResponder(responder)
        // IME guard: never interrupt active composition.
        if let textView = responder as? NSTextView, textView.hasMarkedText() {
            return success
        }
        if success {
            firstResponderCb?(responder)
        } else if responder == nil {
            // An explicit user-driven resign (e.g. clicking the kb-lock icon calls
            // makeFirstResponder(nil)) was refused by the current first responder —
            // typically RichTextView / NSTextView, which returns false from
            // resignFirstResponder() when AppKit believes it should stay focused.
            // The responder chain didn't actually change, but we still honor the
            // user's intent: fire the callback with nil so the UI tracker clears
            // isEditingText and the kb-lock indicator dismisses.
            firstResponderCb?(nil)
        }
        return success
    }
}
