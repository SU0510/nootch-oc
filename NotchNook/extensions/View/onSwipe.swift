//
//  onSwipe.swift
//  NotchNook
//
//  Created by Igor Marcossi on 22/05/24.
//

import Cocoa
import SwiftUI

class ScrollWheelView: NSView {
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

struct ScrollWheelViewRepresentable: NSViewRepresentable {
    var onDragChanged: (CGSize, CGPoint, CGSize, () -> Void) -> Void
    var onDragEnded: (CGSize, CGPoint, CGSize) -> Void

    func makeNSView(context: Context) -> ScrollWheelView {
        let scrollWheelView = ScrollWheelView()
        scrollWheelView.onDragChanged = onDragChanged
        scrollWheelView.onDragEnded = onDragEnded
        return scrollWheelView
    }

    func updateNSView(_ nsView: ScrollWheelView, context: Context) {
        // Update the NSView if needed.
    }
}
