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
    
#if !SETAPP_BUILD
    @Environment(\.sparkleManager) private var sparkleManager
#endif
    @Environment(\.notchNook) private var notchNook
    var body: some View {
        Image(.internalAppIconPaddingless)
            .resizable()
            .scaledToFit()
            .padding(EdgeInsets(top: 6, leading: 6, bottom: 5, trailing: 6))
            .quickPeekScaling(scaling: notchNook.quickPeeks?.first?.anchor == .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .onTapGesture {
#if !SETAPP_BUILD
                sparkleManager.checkForUpdates()
#endif
                ActiveLiveActivitiesManager.shared.activeLiveActivities.remove(.updateAvailable)
            }
            .onHover { hovering in
                if enableQuickPeek {
                    notchNook.quickPeeks = hovering ? quickPeeks : nil
                }
            }
    }
}
