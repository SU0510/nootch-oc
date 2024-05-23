//
//  ArrowForPanningView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//

import SwiftUI

struct ArrowForPanningView: View {
    var x: CGFloat
    @State private var activated = false
    @State private var right = false
    var body: some View {
        let interpolator = interpolatorBuilder([0, 16], value: abs(x))
        Image(systemName: (x == 0 && !right) || x < 0 ? "backward.end.fill" : "forward.end.fill")
            .padding(.top, 2)
            .font(.system(size: 12))
            .foregroundStyle(activated ? .blue : .white)
            .opacity(activated ? 0.75 : interpolator([0, 0.25], false))
            .scaleEffect(interpolator([0.01, 1], false))
            .offset(x: x)
            .onChange(of: x) {
                if x == 0 { return }
                let newRight = $1 > 0
                if right != newRight {
                    right = newRight
                }
            }
            .onChange(of: abs(x) > 15) { old, new in
                if !old && new {
                    activated = true
                    withAnimation { activated = false }
                }
            }
    }
}
