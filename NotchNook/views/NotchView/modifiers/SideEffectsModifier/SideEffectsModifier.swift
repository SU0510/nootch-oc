//
//  SideEffectsModifier.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/06/24.
//

import SwiftUI
import Defaults


extension NotchView {
    struct SideEffectsModifier: ViewModifier {
        var state: NotchViewModel
        
        @Default(.intro) internal var intro
        @Default(.lastBuildNumber) internal var lastBuildNumber
        @Default(.liveActivitiesSettings) internal var liveActivitiesSettings
        @Environment(\.generalSettings) internal var generalSettings
        @Environment(\.notchNook) internal var notchNook
        @Environment(\.sparkleManager) internal var sparkleManager
        @Environment(\.showChangelog) internal var showChangelog
        @Environment(\.closeNotch) internal var closeNotch
        @Environment(\.isEditingText) internal var isEditingText
        @Environment(\.isKeyWindow) internal var isKeyWindow
        
        func body(content: Content) -> some View {
            content
                .onAppear {
                    checkForUpdates()
                    resetTrialAndHandleChangelog()
                    insertUpdateLAIfOldVersion()
                    fetchEvents()
                }
                .onChange(of: liveActivitiesSettings.enabledLiveActivities, initial: true) { old, new in
                    if !old.contains(.calendar) && new.contains(.calendar) {
                        Task { try? await CalendarManager.shared.fetchEventsForDaysOffset(CalendarWidgetView.showingDatesCount) }
                    }
                }
                .onChange(of: state.hoveredDropTargetID) { if $0 != $1 && $1 != nil { vibrate() } }
                .onChange(of: intro, initial: true) { _, new in
                    doAfter(0.3) { withAnimation(NotchView.intenseAnimation) { state.showIntro = new } }
                }
                .onChange(of: generalSettings.notchWidthFineTune) { _, _ in
                    if !state.fineTuningNotchWidth {
                        withAnimation(NotchView.intenseAnimation) { state.fineTuningNotchWidth = true }
                    }
                }
                .onChangeDebounced(of: generalSettings.notchWidthFineTune, delay: 2) { _ in
                    withAnimation(NotchView.intenseAnimation) { state.fineTuningNotchWidth = false }
                }
                .onChangeDebounced(of: state.panRawPadding, delay: 0.05) { _ in
                    withAnimation(.smooth) { state.panRawPadding = .zero }
                }
                .onChangeDebounced(of: state.scaleDown, delay: 0.05) { _ in
                    withAnimation(.smooth) { state.scaleDown = 0 }
                }
                .onChange(of: GlobalBrightnessAndVolume.shared.brightness) { _, new in
                    withAnimation(.bouncySmooth) {
                        notchNook.indicator = .init(kind: .brightness, value: new)
                    }
                }
                .onChange(of: GlobalBrightnessAndVolume.shared.id) { _, _ in
                    withAnimation(.bouncySmooth) {
                        notchNook.indicator = .init(kind: .brightness, value: GlobalBrightnessAndVolume.shared.brightness)
                    }
                }
                .onChange(of: isKeyWindow) { _, newVal in
                    if !newVal && (!generalSettings.lockNNWhenTyping || !isEditingText) && !notchNook.locked {
                        closeNotch(false, false)
                    }
                }
        }
    }
}
