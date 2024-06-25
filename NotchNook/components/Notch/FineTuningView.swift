//
//  FineTuningView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import SwiftUI

struct FineTuningView: View {
    var fineTuningValue: Double
    @Environment(\.notchSize) private var notchSize
    var body: some View {
        let rulerColor = Color.fineTuningBG
        HStack(spacing: 8) {
            HStack(spacing: 0) {
                rulerColor.frame(maxWidth: 1, maxHeight: 8)
                rulerColor.frame(maxWidth: .infinity, maxHeight: 1)
            }
            .frame(maxWidth: .infinity)
            .compositingGroup()
            .opacity(0.25)
            
            Text("\(fineTuningValue > 0 ? "+" : "")\(Int(fineTuningValue))")
                .contentTransition(.numericText())
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(.fineTuningBG)
                .fontWeight(.semibold)

            HStack(spacing: 0) {
                rulerColor.frame(maxWidth: .infinity, maxHeight: 1)
                rulerColor.frame(maxWidth: 1, maxHeight: 8)
            }
            .frame(maxWidth: .infinity)
            .compositingGroup()
            .opacity(0.25)
        }
        .padding(12)
        .frame(width: notchSize.width + fineTuningValue)
        .animation(.spring, value: fineTuningValue)
        .transition(.scaleAndBlur(anchor: .top))
    }
}
