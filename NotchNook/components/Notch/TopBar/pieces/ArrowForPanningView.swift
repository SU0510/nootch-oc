//
//  ArrowForPanningView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//

import SwiftUI

struct ArrowForPanningView: View {
    var x: CGFloat
    var right: Bool
    var inverted = false
    var counter: Int
    
    @State private var isAnimating = false
    
    var body: some View {
        let actionRight = inverted ? !right : right
        let maxPanDrag = NotchView.maxHPanDrag
        let interpolator = interpolatorBuilder([0, maxPanDrag], value: abs(x))
        // Center triangles
        HStack(spacing: -6) {
            RoundedTriangle().fill(.nonShockingWhite)
            RoundedTriangle().fill(.nonShockingWhite)
        }
        .frame(width: 24, height: 12)
        .scaleEffect(x: actionRight ? 1 : -1)
        .opacity(isAnimating ? 0.75 : min(0.25, interpolator([0, 1], false, .linear)))
        .animation(nil, value: isAnimating)
        .scaleEffect(isAnimating ? 0.85 : interpolator([0.3, 0.85], false, .linear))
        .offset(x: isAnimating ? 32 * (right ? 1 : -1) : x * 0.5)
        .animation(.interactiveSpring, value: x)
        .onChange(of: counter) { old, new in
            if (right && new > old) || (!right && old > new) {
                withAnimation(.spring(duration: 0.4, bounce: 0.4)) {
                    isAnimating = true
                } completion: {
                    isAnimating = false
                    if actionRight {
                        MediaManager.shared.goToNextTrack()
                    } else {
                        MediaManager.shared.goToPreviousTrack()
                    }
                }
            }
        }
    }
}
