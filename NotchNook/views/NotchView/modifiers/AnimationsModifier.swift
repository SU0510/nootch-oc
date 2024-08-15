//
//  AnimationsModifier.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/06/24.
//

import SwiftUI
import Defaults

extension NotchView {
    struct AnimationsModifier: ViewModifier {
        var disableNotchNook: Bool
        @Default(.intro) private var intro
        @Default(.nookSettings) private var nookSettings
        
        func body(content: Content) -> some View {
            content
                .animation(.smooth, value: disableNotchNook)
                .animation(.bouncySmooth, value: ActiveLiveActivitiesManager.shared.activeLiveActivities)
                .animation(.bouncySmooth, value: nookSettings)
                .subToAllWidgetsSettingsChanges(animation: .bouncySmooth)
        }
    }
}
