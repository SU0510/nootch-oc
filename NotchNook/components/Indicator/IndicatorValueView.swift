//
//  IndicatorValueView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/07/24.
//

import SwiftUI

struct IndicatorValueView: View, Equatable {
    static func == (lhs: IndicatorValueView, rhs: IndicatorValueView) -> Bool {
        lhs.value == rhs.value
    }
    
    let value: Double
    
    var body: some View {
        HStack(spacing: 0) {
            let volStrArr = Array("\(Int(value * 100))".split(separator: "").enumerated())
            ForEach(volStrArr, id: \.offset) { i, char in
                Text(char)
                    .id(i)
                    .transition(.asymmetric(insertion: .opacity.animation(.easeOut(duration: 0.15).delay(0.1)), removal: .identity))
            }
            Text("%")
        }
        .fixedSize(horizontal: true, vertical: false)
        .contentTransition(.identity)
        .geometryGroup()
        .multilineTextAlignment(.trailing)
    }
}
