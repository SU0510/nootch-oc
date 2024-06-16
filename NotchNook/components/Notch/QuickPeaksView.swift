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
        HStack(spacing: 8) {
            ForEach(quickPeaks) { QuickPeakView(quickPeak: $0) }
        }
    }
}

struct QuickPeakView: View {
    var quickPeak: NotchNook.QuickPeak
    var body: some View {
            HStack(spacing: 4) {
                if let icon = quickPeak.icon {
                    Image(systemName: icon)
                        .opacity(0.5)
                }
                Text(quickPeak.text)
            }
            .opacity(0.5)
            .foregroundStyle(.white)
            .font(.system(size: 10, weight: .medium))
            .padding(.bottom, 6)
    }
}


