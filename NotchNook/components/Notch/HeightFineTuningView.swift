//
//  HeightFineTuningView.swift
//  NotchNook
//
//  Created by Lori Montenegro on 07/11/24.
//

import SwiftUI

struct HeightFineTuningView: View {
    
    var fineTuningValue: Double
    
    @Environment(\.notchSize) private var notchSize
    
    var body: some View {
        Text("\(fineTuningValue > 0 ? "+" : "")\(Int(fineTuningValue))")
            .contentTransition(.numericText())
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(.fineTuningBG)
            .fontWeight(.semibold)
//            .padding(12)
            .frame(width: 40, height: notchSize.height, alignment: .leading)
            .animation(.spring, value: fineTuningValue)
    }
}
