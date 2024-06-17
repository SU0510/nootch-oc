//
//  QuickPeaksView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 16/06/24.
//

import SwiftUI

struct QuickPeaksView: View {
    var quickPeaks: [NotchNook.QuickPeak]
    var body: some View {
        TheMarquee(width: NotchShape.defaultNotchWidth + (TopBarView.liveActionWidth * 2), spacingBetweenElements: 12) {
            HStack(spacing: 12) {
                ForEach(quickPeaks) { QuickPeakView(quickPeak: $0) }
            }
        }
    }
}

struct QuickPeakView: View {
    var quickPeak: NotchNook.QuickPeak
    var body: some View {
            HStack(spacing: 4) {
                if let icon = quickPeak.icon {
                    Image(systemName: icon)
                        .opacity(0.75)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(quickPeak.text)
                    .font(.system(size: 12, weight: .medium))
            }
            .opacity(0.5)
            .foregroundStyle(.white)
            .padding(EdgeInsets(top: 9, leading: 0, bottom: 4, trailing: 0))
    }
}


