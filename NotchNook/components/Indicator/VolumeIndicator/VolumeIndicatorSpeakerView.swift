//
//  VolumeIndicatorSpeakerView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/07/24.
//

import SwiftUI

struct VolumeIndicatorSpeakerView: View, Equatable {
    static func == (lhs: VolumeIndicatorSpeakerView, rhs: VolumeIndicatorSpeakerView) -> Bool {
        lhs.volumeValue == rhs.volumeValue &&
        lhs.overflowAmount == rhs.overflowAmount &&
        lhs.baseColor == rhs.baseColor
    }
    
    let volumeValue: Double
    let overflowAmount: Double
    let baseColor: Color
    
    
    var body: some View {
        let iconNum = volumeValue > 0.33 ? volumeValue > 0.66 ? 3 : 2 : 1
        HStack(spacing: -1) {
            Image(systemName: volumeValue > 0 ? "speaker.fill" : "speaker.slash.fill")
            if volumeValue > 0 {
                let scale = 1.75
                HStack(spacing: 1.5 * scale) {
                    VolumeIndicatorSpeakerWaveShape()
                        .stroke(.nonShockingWhite, style: .init(lineWidth: 1.25 * scale, lineCap: .round))
                        .frame(width: 0.6 * scale, height: 3.5 * scale)
                        .padding(.trailing, 0.15)
                    if volumeValue > 0.33 {
                        VolumeIndicatorSpeakerWaveShape()
                            .stroke(.nonShockingWhite, style: .init(lineWidth: 1.25 * scale, lineCap: .round))
                            .frame(width: 1 * scale, height: 6.5 * scale)
                    }
                    if volumeValue > 0.66 {
                        VolumeIndicatorSpeakerWaveShape()
                            .stroke(.nonShockingWhite, style: .init(lineWidth: 1.25 * scale, lineCap: .round))
                            .frame(width: 1.3 * scale, height: 9 * scale)
                    }
                }
            }
        }
        .contentTransition(.symbolEffect(.replace))
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(baseColor)
        .frame(width: 25, height: 22)
    }
}
