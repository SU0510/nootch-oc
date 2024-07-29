//
//  UpdateAppIconView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import SwiftUI

struct UpdateAppIconView: View {
    var enableQuickPeek = true
    var quickPeeks: [NotchNookState.QuickPeek] { [.init(icon: "sparkles", text: "New update available for NotchNook!", iconColor: .yellow)] }
    
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
                ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.updateAvailable)
            }
            .onHover { hovering in
                if enableQuickPeek {
                    notchNook.quickPeeks = hovering ? quickPeeks : nil
                }
            }
    }
}
