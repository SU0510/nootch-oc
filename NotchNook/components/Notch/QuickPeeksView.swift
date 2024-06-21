//
//  QuickPeeksView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 16/06/24.
//

import SwiftUI

struct QuickPeeksView: View {
    var quickPeeks: [NotchNook.QuickPeek]
    var body: some View {
        TheMarquee(width: NotchShape.defaultNotchWidth + (TopBarView.liveActionWidth * 2), spacingBetweenElements: 12) {
            HStack(spacing: 12) {
                ForEach(quickPeeks) { QuickPeekView(quickPeek: $0) }
            }
        }
    }
}

struct QuickPeekView: View {
    var quickPeek: NotchNook.QuickPeek
    var body: some View {
            HStack(spacing: 4) {
                if let icon = quickPeek.icon {
                    Image(systemName: icon)
                        .opacity(quickPeek.iconColor == nil ? 0.5 : 1)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(quickPeek.iconColor ?? .white)
                }
                Text(quickPeek.text)
                    .font(.system(size: 12, weight: .medium))
            }
            .opacity(0.5)
            .foregroundStyle(.white)
            .padding(EdgeInsets(top: 7, leading: 0, bottom: 3, trailing: 0))
    }
}


