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
    
    init(value: Binding<Double>, range: ClosedRange<Double>, rangeManual: ClosedRange<Double>? = nil, step: Double = 1) {
        self._value = value
        self.range = range
        self.rangeManual = rangeManual
        self.step = step
    }
    
    init(value: Binding<CGFloat>, range: ClosedRange<Double>, rangeManual: ClosedRange<Double>? = nil, step: Double = 1) {
        self._value = Binding<Double>(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = CGFloat($0) }
        )
        self.range = range
        self.rangeManual = rangeManual
        self.step = step
    }
    
    var body: some View {
        let rangeManual = rangeManual ?? range
        let rangeAmount = range.upperBound - range.lowerBound
        HStack {
            if (rangeAmount / step) > 20 {
                Slider(value: Binding(get: { value }, set: { newValue in
                    let base: Int = Int(newValue.rounded())
                    let modulo: Int = base % Int(step)
                    value = Double(base - modulo)
                }), in: range)
            } else {
                Slider(value: $value, in: range, step: step)
            }
            IntegerTextField(value: $value, minVal: rangeManual.lowerBound, maxVal: rangeManual.upperBound)
                .frame(width: 40, height: 0)
        }
    }
}
