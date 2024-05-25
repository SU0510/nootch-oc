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
        let maxPanDrag = NotchView.maxHPanDrag
        let interpolator = interpolatorBuilder([0, maxPanDrag], value: abs(x))
        Image(systemName: !right ? "backward.end.fill" : "forward.end.fill")
            .padding(.top, 10)
            .font(.system(size: 12))
            .opacity(activated ? 0.75 : min(0.25, interpolator([0, 0.5], false)))
            .foregroundStyle(activated ? .blue : .white)
            .animation(nil, value: activated)
            .scaleEffect(activated ? 0.85 : interpolator([0.1, 0.85], false))
            .blur(radius: activated ? 0 : max(0, interpolator([14, -10], false)))
            .offset(x: activated ? 32 * (right ? 1 : -1) : x * 0.5)
            .animation(.interactiveSpring, value: x)
            .onChange(of: abs(x) > maxPanDrag) { old, new in
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
