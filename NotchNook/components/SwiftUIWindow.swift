//
//  SwiftUIWindow.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/06/24.
//

import SwiftUI
import AppKit

class SwiftUIWindow<Content>: NSWindow, NSWindowDelegate where Content: View {
    private var viewBuilder: () -> Content
    private var onClose: (() -> ())?
    
    init(styleMask: NSWindow.StyleMask, content: @escaping () -> Content, onClose: (() -> ())? = nil) {
        self.viewBuilder = content
        self.onClose = onClose
        super.init(contentRect: NSRect(x: 0, y: 0, width: 0, height: 0), styleMask: styleMask, backing: .buffered, defer: true)
        self.delegate = self
    }
    
    func show() {
        let contentView = viewBuilder().environment(\.closeWindow, self.close)
        let view = NSHostingView(rootView: contentView)
        self.contentView = view
        let intrinsicSize = view.intrinsicContentSize
        let screenF = self.screen?.frame.size ?? .zero
        
        var finalSize = intrinsicSize
        if self.toolbar != nil {
            finalSize.height += 51  // Add toolbar height if present
        }
        self.setContentSize(finalSize)
        self.setFrameOrigin(.init(
            x: (screenF.width - finalSize.width) / 2,
            y: (screenF.height - finalSize.height) / 2
        ))
        
        
        self.makeKeyAndOrderFront(nil)
    }
    
    func windowWillClose(_ notification: Notification) {
        self.contentView = nil
        onClose?()
    }
}
