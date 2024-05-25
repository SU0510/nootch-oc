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
    @State private var activated = false
//    @State private var right = false
    var body: some View {
        let maxPanDrag = NotchView.maxPanDrag
        let interpolator = interpolatorBuilder([0, maxPanDrag], value: abs(x))
        Image(systemName: !right ? "backward.end.fill" : "forward.end.fill")
            .padding(.top, 2)
            .font(.system(size: 12))
            .opacity(activated ? 0.75 : interpolator([0, 0.25], false))
            .foregroundStyle(activated ? .blue : .white)
            .animation(nil, value: activated)
            .scaleEffect(activated ? 1 : interpolator([0.01, 1], false))
            .blur(radius: activated ? 0 : max(0, interpolator([14, -5], false)))
            .offset(x: activated ? 32 * (right ? 1 : -1) : x)
            .animation(.interactiveSpring, value: x)
            .onChange(of: abs(x) > 16) { old, new in
                if !old && new {
                    withAnimation(.bouncy) {
                        activated = true
                    } completion: {
                        activated = false
                    }
                }
            }
    }
}
