//
//  UpdateAppIconView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import SwiftUI

struct UpdateAppIconView: View {
    var laPrefs: LiveActivitiesSettings
    
    var quickPeeks: [NotchNook.QuickPeek] { [.init(icon: "sparkles", text: "New update available for NotchNook!", iconColor: .yellow)] }
    
    @Environment(\.sparkleManager) private var sparkleManager
    @Environment(\.notchNook) private var notchNook
    var body: some View {
        Image(.internalAppIconPaddingless)
            .resizable()
            .scaledToFit()
            .padding(EdgeInsets(top: 6, leading: 6, bottom: 5, trailing: 6))
            .quickPeekScaling(scaling: notchNook.quickPeeks != nil)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .onTapGesture {
                sparkleManager.checkForUpdates()
                LiveActivitiesManager.shared.activeLiveActivities.remove(.updateAvailable)
            }
            .onHover { hovering in
                if laPrefs.enableQuickPeek {
                    notchNook.quickPeeks = hovering ? quickPeeks : nil
                }
            }
    }
}
