//
//  EnvironmentsModifier.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/06/24.
//

import SwiftUI
import Defaults

extension NotchView {
    struct EnvironmentsModifier: ViewModifier {
        var state: NotchViewModel
        @Default(.generalSettings) internal var generalSettings
        @Default(.trialInitialTime) internal var trialInitialTime
        @Default(.license) internal var license
        @Namespace internal var ns
        
        @Environment(\.notchNook) internal var notchNook
        @Environment(\.canBecomeKey) internal var canBecomeKey
        @Environment(\.makeKeyWindow) internal var makeKeyWindow
        @Environment(\.resignFirstResponder) internal var resignFirstResponder
        @Environment(\.focusFrontmostWindow) internal var focusFrontmostWindow
        @Environment(\.isEditingText) internal var isEditingText
        
        func body(content: Content) -> some View {
            content
                .environment(\.hideNotch, hideNotch)
                .environment(\.closeNotch, closeNotch)
                .environment(\.checkTrialOver, checkTrialOver)
                .environment(\.openNotch, openNotch)
                .environment(\.namespace, ns)
                .environment(\.trialOver, state.trialOver)
                .transformEnvironment(\.notchSize) { $0.width += generalSettings.notchWidthFineTune }
                .preferredColorScheme(.dark)
        }
    }
}
