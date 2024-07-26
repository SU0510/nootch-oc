//
//  VolumeIndicatorBarView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/07/24.
//

import SwiftUI

struct VolumeIndicatorBarView: View, Equatable {
    static func == (lhs: VolumeIndicatorBarView, rhs: VolumeIndicatorBarView) -> Bool {
        lhs.totalWidth == rhs.totalWidth &&
        lhs.volumeValue == rhs.volumeValue &&
        lhs.overflowAmount == rhs.overflowAmount &&
        lhs.baseColor == rhs.baseColor &&
        lhs.barsHeight == rhs.barsHeight &&
        lhs.barsWidth == rhs.barsWidth &&
        lhs.barsSpacing == rhs.barsSpacing
    }
    
    let totalWidth: Double
    let volumeValue: Double
    let overflowAmount: Double
    let baseColor: Color
    var barsHeight: Double = 12
    var barsWidth: Double = 3
    var barsSpacing: Double = 3.5
    
    var barsNumber: Int { Int(totalWidth / (barsWidth + barsSpacing)) }
    var volumeLastBar: Int { Int(Double(barsNumber) * volumeValue) }
    
    private var volumeInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0, 1.0], value: volumeValue) }
    
    @State private var localVolumeLastBar = 0
    @State private var timer: Timer?
    
    func getBarColor(index: Int) -> Color {
        if localVolumeLastBar < index {
            return .white.opacity(0.25)
        } else {
            let barsDouble = Double(barsNumber)
            
            let colors: [Int:Color] = [
                Int(barsDouble * 0.675): Color(red: 0.7019, green: 0.7019, blue: 0.7019),
                Int(barsDouble * 0.925): Color(red: 0.9176, green: 0.9254, blue: 0.5176),
                Int(barsDouble * 1): Color(red: 0.9058, green: 0.3882, blue: 0.3882)
            ]
            
            if let foundColor = Array(colors).sorted(by: { $0.key < $1.key }).first(where: { $0.key > index }) {
                return foundColor.value
            }
            return .white
        }
    }
    
    var body: some View {
        HStack(spacing: barsSpacing) {
            ForEach(0..<barsNumber) { barIndex in
                VolumeIndicatorBarCapsuleView(color: getBarColor(index: barIndex), active: localVolumeLastBar >= barIndex)
                    .transaction { $0.disablesAnimations = true }
                    .frame(width: barsWidth)
                    .id("bar-\(barIndex)")
            }
        }
        .frame(height: barsHeight)
        .onAppear { localVolumeLastBar = volumeLastBar }
        .onChange(of: volumeLastBar) { old, new in
            timer?.invalidate()
            let difference = Double(abs(new - localVolumeLastBar))
            timer = Timer.scheduledTimer(withTimeInterval: 0.125 / difference, repeats: true) { timer in
                if localVolumeLastBar != new {
                    localVolumeLastBar += new > old ? 1 : -1
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}
