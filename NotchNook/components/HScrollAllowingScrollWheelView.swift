//
//  HScrollAllowingScrollWheelView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/06/24.
//

import SwiftUI

struct HScrollAllowingScrollWheelView<Content: View>: NSViewRepresentable {
    var content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = CustomScrollView()
        scrollView.usesPredominantAxisScrolling = true
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.horizontalScrollElasticity = .none
        scrollView.autohidesScrollers = true
        
        let hostingView = NSHostingView(rootView: content())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.documentView = hostingView
        
        scrollView.heightAnchor.constraint(equalToConstant: hostingView.intrinsicContentSize.height).isActive = true
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let hostingView = nsView.documentView as? NSHostingView<Content> {
            hostingView.rootView = content()
            nsView.needsLayout = true
            nsView.heightAnchor.constraint(equalToConstant: hostingView.intrinsicContentSize.height).isActive = true
        }
    }
}

class CustomScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        if abs(event.scrollingDeltaY) > abs(event.scrollingDeltaX) {
            var newScrollOrigin: NSPoint
            let currentScrollOrigin = self.contentView.bounds.origin
            let maximumX = self.documentView!.frame.size.width - self.contentView.bounds.size.width
            let delta = event.scrollingDeltaY
            
            if currentScrollOrigin.x - delta < 0 {
                newScrollOrigin = NSPoint(x: 0, y: currentScrollOrigin.y)
            } else if currentScrollOrigin.x - delta > maximumX {
                newScrollOrigin = NSPoint(x: maximumX, y: currentScrollOrigin.y)
            } else {
                newScrollOrigin = NSPoint(x: currentScrollOrigin.x - delta, y: currentScrollOrigin.y)
            }
            
            self.contentView.scroll(to: newScrollOrigin)
            self.reflectScrolledClipView(self.contentView)
        } else {
            super.scrollWheel(with: event)
        }
    }
}
