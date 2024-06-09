//
//  onSwipe.swift
//  NotchNook
//
//  Created by Igor Marcossi on 22/05/24.
//

import Cocoa
import SwiftUI

class ScrollWheelNSView: NSView {
    var onDragChanged: ((CGSize, CGPoint, CGSize, () -> Void) -> Void)?
    var onDragEnded: ((CGSize, CGPoint, CGSize) -> Void)?
    
    private var initialScrollEvent: NSEvent?
    private var cumulativeTranslation: CGSize = .zero
    private var smoothedScrollDelta: CGPoint = .zero
    private let smoothingFactor: CGFloat = 0.3  // Adjust this value to tune the smoothing effect
    
    override func scrollWheel(with event: NSEvent) {
        switch event.phase {
            case .began:
                initialScrollEvent = event
                cumulativeTranslation = .zero
                smoothedScrollDelta = .zero
            case .changed:
                let delta = CGSize(width: event.scrollingDeltaX, height: event.scrollingDeltaY)
                cumulativeTranslation.width += delta.width
                cumulativeTranslation.height += delta.height
                let currentScrollDelta = CGPoint(x: event.scrollingDeltaX, y: event.scrollingDeltaY)
                // Apply exponential smoothing
                smoothedScrollDelta.x = smoothingFactor * currentScrollDelta.x + (1 - smoothingFactor) * smoothedScrollDelta.x
                smoothedScrollDelta.y = smoothingFactor * currentScrollDelta.y + (1 - smoothingFactor) * smoothedScrollDelta.y
                let velocity = calculateVelocity(currentEvent: event, initialEvent: initialScrollEvent)
                onDragChanged?(cumulativeTranslation, smoothedScrollDelta, velocity, cancelGesture)
            case .ended:
                let velocity = calculateVelocity(currentEvent: event, initialEvent: initialScrollEvent)
                onDragEnded?(cumulativeTranslation, smoothedScrollDelta, velocity)
                cumulativeTranslation = .zero
                smoothedScrollDelta = .zero
            default:
                break
        }
    }
    
    private func cancelGesture() {
        cumulativeTranslation = .zero
        smoothedScrollDelta = .zero
        initialScrollEvent = nil
    }
    
    private func calculateVelocity(currentEvent: NSEvent, initialEvent: NSEvent?) -> CGSize {
        guard let initial = initialEvent else {
            return CGSize.zero
        }
        let timeInterval = currentEvent.timestamp - initial.timestamp
        if timeInterval > 0 {
            let deltaX = (currentEvent.scrollingDeltaX - initial.scrollingDeltaX) / CGFloat(timeInterval)
            let deltaY = (currentEvent.scrollingDeltaY - initial.scrollingDeltaY) / CGFloat(timeInterval)
            return CGSize(width: deltaX, height: deltaY)
        }
        return CGSize.zero
    }
}

struct ScrollWheelViewRepresentable<Content: View>: NSViewRepresentable {
    var onDragChanged: (CGSize, CGPoint, CGSize, () -> Void) -> Void
    var onDragEnded: (CGSize, CGPoint, CGSize) -> Void
    var content: () -> Content
    
    init(onDragChanged: @escaping (CGSize, CGPoint, CGSize, () -> Void) -> Void,
         onDragEnded: @escaping (CGSize, CGPoint, CGSize) -> Void,
         @ViewBuilder content: @escaping () -> Content = { EmptyView() }) {
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
        self.content = content
    }
    
    func makeNSView(context: Context) -> ScrollWheelNSView {
        let scrollWheelNSView = ScrollWheelNSView()
        scrollWheelNSView.onDragChanged = onDragChanged
        scrollWheelNSView.onDragEnded = onDragEnded
        scrollWheelNSView.translatesAutoresizingMaskIntoConstraints = false
        
        setupHostingView(for: scrollWheelNSView, with: content)
        
        return scrollWheelNSView
    }
    
    func updateNSView(_ nsView: ScrollWheelNSView, context: Context) {
        nsView.onDragChanged = onDragChanged
        nsView.onDragEnded = onDragEnded
//
        setupHostingView(for: nsView, with: content)
    }
    
    private func setupHostingView(for nsView: NSView, with content: () -> Content) {
        if let hostingView = nsView.subviews.compactMap({ $0 as? NSHostingView<Content> }).first {
                hostingView.rootView = content()
        } else {
            let hostingView = NSHostingView(rootView: content())
            hostingView.translatesAutoresizingMaskIntoConstraints = false
//            hostingView.sizingOptions = .intrinsicContentSize
            nsView.addSubview(hostingView)
            
            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: nsView.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: nsView.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: nsView.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: nsView.bottomAnchor)
            ])
        }
    }
}
