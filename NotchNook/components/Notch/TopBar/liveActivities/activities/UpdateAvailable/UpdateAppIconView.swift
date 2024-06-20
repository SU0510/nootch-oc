//
//  UpdateAppIconView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import SwiftUI

struct UpdateAppIconView: View {
    var laPrefs: LiveActivitiesSettings
    
    var quickPeaks: [NotchNook.QuickPeak] { [.init(icon: "sparkles", text: "New update available for NotchNook!", iconColor: .yellow)] }
    
    @Environment(\.sparkleManager) private var sparkleManager
    var body: some View {
        Image(.internalAppIconPaddingless)
            .resizable()
            .scaledToFit()
            .padding(EdgeInsets(top: 6, leading: 6, bottom: 5, trailing: 6))
            .quickPeakScaling()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .onTapGesture {
                sparkleManager.checkForUpdates()
                NotchNook.shared.activeLiveActivities.remove(.updateAvailable)
            }
            .onHover { hovering in
                if laPrefs.enableQuickPeak {
                    NotchNook.shared.quickPeaks = hovering ? quickPeaks : nil
                }
            }
    }
}
