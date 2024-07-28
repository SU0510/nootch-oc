//
//  NonHyphenatingText.swift
//  NotchNook
//
//  Created by Lori Montenegro on 28/07/24.
//

import SwiftUI

struct NonHyphenatingText: NSViewRepresentable {
    let text: String
    let maxWidth: CGFloat = 56
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.isEditable = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: 10)
        textField.cell?.wraps = true
        textField.cell?.isScrollable = false
        textField.cell?.truncatesLastVisibleLine = true
        textField.usesSingleLineMode = false
        textField.maximumNumberOfLines = 2
        textField.preferredMaxLayoutWidth = maxWidth
        textField.cell?.usesSingleLineMode = false
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
        nsView.frame.size.width = maxWidth
    }
}
