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
        
//        if let initialScrollPos = initialScrollPos {
//            doAfter(0) {
//                scrollView.contentView.scroll(to: .init(x: scrollView.contentView.bounds.origin.x, y: initialScrollPos))
//            }
//        }
        
        return scrollView
    }
    
    public func updateNSView(_ view: NSViewType, context: Context) {
        context.coordinator.onScrollChange = onScrollChange
//        let currentScrollPosition = view.contentView.bounds.origin
//          
//          // Update the document view if needed
//          
//        doAfter(0.5) {
//            // Restore scroll position
//            view.contentView.scroll(to: currentScrollPosition)
////            view.reflectScrolledClipView(view.contentView)
//        }
    }
}

// MARK: RichTextPresenter

//public extension CRichTextEditor {
//    
//    /// Get the currently selected range.
//    var selectedRange: NSRange {
//        textView.selectedRange
//    }
//}

// MARK: RichTextReader

public extension CRichTextEditor {
    
    /// Get the string that is managed by the editor.
    var attributedString: NSAttributedString {
        text
    }
}

// MARK: RichTextWriter

//public extension CRichTextEditor {
//    
//    /// Get the mutable string that is managed by the editor.
//    var mutableAttributedString: NSMutableAttributedString? {
//        textView.mutableAttributedString
//    }
//}


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
}
