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
    @State private var activated = false

    var body: some View {
        let actionRight = inverted ? !right : right
        let maxPanDrag = NotchView.maxHPanDrag
        let interpolator = interpolatorBuilder([0, maxPanDrag], value: abs(x))
        Image(systemName: !actionRight ? "backward.end.fill" : "forward.end.fill")
            .padding(.top, 10)
            .font(.system(size: 12))
            .opacity(activated ? 0.75 : min(0.25, interpolator([0, 1], false, .linear)))
            .foregroundStyle(activated ? .blue : .nonShockingWhite)
            .animation(nil, value: activated)
            .scaleEffect(activated ? 0.85 : interpolator([0.3, 0.85], false, .linear))
            .blur(radius: activated ? 0 : max(0, interpolator([14, -10], false, .linear)))
            .offset(x: activated ? 32 * (right ? 1 : -1) : x * 0.5)
            .animation(.interactiveSpring, value: x)
            .onChange(of: counter) { old, new in
                if (right && new > old) || (!right && old > new) {
                    withAnimation(.bouncy) {
                        activated = true
                    } completion: {
                        activated = false
                        if actionRight {
                            MediaControls.shared.goToNextTrack()
                        } else {
                            MediaControls.shared.goToPreviousTrack()
                        }
                    }
                }
            }
    }
}
