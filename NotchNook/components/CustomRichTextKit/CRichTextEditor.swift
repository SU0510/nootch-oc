//
//  CRichTextEditor.swift
//  RichTextKit
//
//  Created by Daniel Saidi on 2022-05-21.
//  Copyright © 2022-2024 Daniel Saidi. All rights reserved.
//

import SwiftUI
import RichTextKit

public struct CRichTextEditor: NSViewRepresentable {
    @Binding var text: NSAttributedString
    var context: RichTextContext
    var format: RichTextDataFormat = .archivedData
    var initialScrollPos: Double? = nil
    var onScrollChange: ((Double) -> ())? = nil
    var viewConfiguration: (RichTextViewComponent) -> Void
    
    public func makeCoordinator() -> CRichTextCoordinator {
        CRichTextCoordinator(
            text: $text,
            textView: RichTextView(),
            richTextContext: context,
            onScrollChange: onScrollChange
        )
    }
    
    public func makeNSView(context: Context) -> some NSScrollView {
        let scrollView = RichTextView.scrollableTextView()
        scrollView.horizontalScrollElasticity = .none
        guard let textView = scrollView.documentView as? RichTextView else { return scrollView }
        textView.delegate = context.coordinator
        context.coordinator.textView = textView
        textView.textContainer?.lineFragmentPadding = 16
        textView.isRichText = true

        // Configure IME-friendly settings
        textView.usesFindBar = false  // Avoid conflicts with IME
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false

        textView.setup(with: text, format: format)
        textView.configuration = context.environment.richTextEditorConfig
        textView.theme = context.environment.richTextEditorStyle
        viewConfiguration(textView)
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(CRichTextCoordinator.scrollViewDidScroll(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        
        return scrollView
    }
    
    public func updateNSView(_ scrollView: NSViewType, context: Context) {
        context.coordinator.onScrollChange = onScrollChange
        guard let textView = scrollView.documentView as? RichTextView else { return }
        textView.scrollViewDidResize(scrollView)
    }
}

// MARK: RichTextReader

public extension CRichTextEditor {
    
    /// Get the string that is managed by the editor.
    var attributedString: NSAttributedString {
        text
    }
}

// MARK: RichTextWriter

public class CRichTextCoordinator: RichTextCoordinator {
    var onScrollChange: ((Double) -> ())?
    
    init(text: Binding<NSAttributedString>, textView: RichTextView, richTextContext: RichTextContext, onScrollChange: ((Double) -> ())?) {
        self.onScrollChange = onScrollChange
        super.init(text: text, textView: textView, richTextContext: richTextContext)
    }
    
    @objc func scrollViewDidScroll(_ notification: Notification) {
        if let scrollView = notification.object as? NSClipView {
            let newScrollPosition = Double(scrollView.documentVisibleRect.origin.y)
            onScrollChange?(newScrollPosition)
        }
    }
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        guard let replacementString = replacementString else { return true }

        // Check if we're in the middle of IME composition, to allow it to complete
        if textView.hasMarkedText() {
            return true
        }

        // For single character input (typing), allow default behavior
        if replacementString.count == 1 {
            return true
        }
        
        // For pasting or larger text insertions
        let mutableAttrString = NSMutableAttributedString(string: replacementString)
        
        // Safely get existing attributes
        let existingAttributes: [NSAttributedString.Key: Any] = {
            guard affectedCharRange.location < textView.textStorage?.length ?? 0 else {
                return [:]
            }
            return textView.textStorage?.attributes(at: affectedCharRange.location, effectiveRange: nil) ?? [:]
        }()
        
        // Apply existing attributes
        mutableAttrString.addAttributes(existingAttributes, range: NSRange(location: 0, length: mutableAttrString.length))
        
        // Ensure text color is always white
        mutableAttrString.addAttribute(.foregroundColor, value: NSColor.nonShockingWhite, range: NSRange(location: 0, length: mutableAttrString.length))
        
        // Safely replace characters
        if affectedCharRange.location <= textView.textStorage?.length ?? 0 {
            textView.textStorage?.replaceCharacters(in: affectedCharRange, with: mutableAttrString)
        } else {
            textView.textStorage?.append(mutableAttrString)
        }
        
        return false
    }
}

class CustomLayoutManager: NSLayoutManager {
    override var extraLineFragmentRect: NSRect { NSRect(x: 0, y: 0, width: 0, height: 0) }
}
