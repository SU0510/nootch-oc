//
//  InlineIntField.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI
import AppKit

struct IntegerTextField: NSViewRepresentable {
    @Binding var value: Double
    var minVal: CGFloat
    var maxVal: CGFloat

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.delegate = context.coordinator
        textField.isBezeled = true
        textField.isEditable = true
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = String(format: "%.0f", value) // Format as integer
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: IntegerTextField

        init(_ parent: IntegerTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                if let intValue = Double(textField.stringValue) {
                    let clampedValue = min(max(CGFloat(intValue), parent.minVal), parent.maxVal)
                    parent.value = clampedValue
                } else {
                    parent.value = Double(Int(parent.minVal)) // Reset to min if invalid input
                }
            }
        }

        func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
            let allowedCharacters = CharacterSet(charactersIn: "0123456789")
            let characterSet = CharacterSet(charactersIn: fieldEditor.string)
            return allowedCharacters.isSuperset(of: characterSet)
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                control.window?.makeFirstResponder(nil) // Resign first responder to lose focus
                return true
            }
            return false
        }
    }
}
