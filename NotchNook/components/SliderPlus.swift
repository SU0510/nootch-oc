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
    var maxWidth: Double = 200
    var useTickMarks: Bool = false

    init(value: Binding<Double>, range: ClosedRange<Double>, rangeManual: ClosedRange<Double>? = nil, step: Double = 1) {
        self._value = value
        self.range = range
        self.rangeManual = rangeManual
        self.step = step
    }
    
    init(value: Binding<CGFloat>, range: ClosedRange<Double>, rangeManual: ClosedRange<Double>? = nil, step: Double = 1, useTickMarks: Bool = false) {
        self._value = Binding<Double>(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = CGFloat($0) }
        )
        self.range = range
        self.rangeManual = rangeManual
        self.step = step
        self.useTickMarks = useTickMarks
    }
    
    init(value: Binding<Int>, range: ClosedRange<Double>, rangeManual: ClosedRange<Double>? = nil, step: Double = 1) {
        self._value = Binding<Double>(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = Int($0) }
        )
        self.range = range
        self.rangeManual = rangeManual
        self.step = step
    }
    
    func getSafeRange(_ r: ClosedRange<Double>) -> ClosedRange<Double> {
        var lower = r.lowerBound
        var upper = r.upperBound
        if lower < 0 { lower = 0 }
        if upper <= lower { upper = max(value, lower) }
        if upper <= lower { upper += 1 }
        return lower...upper
    }
    
    var safeRange: ClosedRange<Double> { getSafeRange(range) }
    
    var safeRangeManual: ClosedRange<Double>? {
        guard let rangeManual else { return nil }
        return getSafeRange(rangeManual)
    }
    
    var rangeAmount: Double { safeRange.upperBound - safeRange.lowerBound }
    
    var safeStep: Double { rangeAmount < step ? rangeAmount : step }
    
    var body: some View {
        let rangeManual = safeRangeManual ?? safeRange
        
        HStack {
            Group {
                if useTickMarks || (rangeAmount / step) <= 20 {
                    // tick marks style
                    Slider(value: $value, in: safeRange, step: safeStep)
                } else {
                    Slider(
                        value: Binding(
                            get: { value },
                            set: { newValue in
                                let base: Int = Int(newValue.rounded())
                                let modulo: Int = base % Int(step)
                                value = Double(base - modulo)
                            }
                        ),
                        in: safeRange
                    )
                }
            }
            .frame(maxWidth: maxWidth)
            
            IntegerTextField(value: $value, minVal: rangeManual.lowerBound, maxVal: rangeManual.upperBound)
                .frame(width: 40, height: 0)
        }
    }
}
