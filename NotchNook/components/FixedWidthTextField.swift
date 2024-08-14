//
//  FixedWidthTextField.swift
//  NotchNook
//
//  Created by Ethan Bills on 8/12/24.
//

import SwiftUI

struct FixedWidthTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isSecure: Bool
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = isSecure ? NSSecureTextField() : NSTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: FixedWidthTextField
        
        init(_ parent: FixedWidthTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            parent.text = textField.stringValue.filter { !$0.isWhitespace }
        }
    }
}
