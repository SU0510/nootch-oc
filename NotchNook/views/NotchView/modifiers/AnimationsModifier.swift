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
//        @Default(.liveActivitiesSettings) private var liveActivitiesSettings
        @Default(.intro) private var intro
        
        func body(content: Content) -> some View {
            content
                .animation(.smooth, value: disableNotchNook)
                .animation(.bouncySmooth, value: ActiveLiveActivitiesManager.shared.activeLiveActivities)
//                .animation(.bouncySmooth, value: ActiveLiveActivitiesManager.shared.activeLiveActivities)
                .animation(.bouncySmooth, value: intro)
        }
    }
}
