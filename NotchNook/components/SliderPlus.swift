//
//  SliderPlus.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/05/24.
//

import SwiftUI

struct SliderPlus: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var rangeManual: ClosedRange<Double>?
    var step: Double = 1
    var body: some View {
        let rangeManual = rangeManual ?? range
        HStack {
            Slider(value: $value, in: range, step: step)
            IntegerTextField(value: $value, minVal: rangeManual.lowerBound, maxVal: rangeManual.upperBound)
                .frame(width: 40, height: 0)
        }
    }
}
