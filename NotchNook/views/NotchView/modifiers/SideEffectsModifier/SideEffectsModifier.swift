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
        var showIndicator: (Indicator?) -> Void
        
        @Default(.intro) internal var intro
        @Default(.lastBuildNumber) internal var lastBuildNumber
        @Default(.liveActivitiesSettings) internal var liveActivitiesSettings
        @Environment(\.generalSettings) internal var generalSettings
        @Environment(\.notchNook) internal var notchNook
#if !SETAPP_BUILD
        @Environment(\.sparkleManager) internal var sparkleManager
#endif
        @Environment(\.showChangelog) internal var showChangelog
        @Environment(\.closeNotch) internal var closeNotch
        @Environment(\.isEditingText) internal var isEditingText
        @Environment(\.checkTrialOver) internal var checkTrialOver
        @Environment(\.isKeyWindow) internal var isKeyWindow
        @Environment(\.notchSize) internal var notchSize
        
        @State private var isAnimating: Bool = false
        
        func body(content: Content) -> some View {
            content
                .onAppear {
#if !SETAPP_BUILD
                    checkForUpdates()
                    resetTrialAndHandleChangelog()
                    checkTrialOver()
#endif
                    insertUpdateLAIfOldVersion()
                    startBriVolKeyListener()
                }
                .onChange(of: liveActivitiesSettings.enableHUDReplacement) {
                    startBriVolKeyListener()
                }
                .onChange(of: liveActivitiesSettings.enabledLiveActivities, initial: true) { old, new in
                    if !old.contains(.calendar) && new.contains(.calendar) {
                        Task {
                            try? await CalendarManager.shared.fetchEvents()
                        }
                    }
                }
                .onChange(of: state.hoveredDropTargetID) { if $0 != $1 && $1 != nil { vibrate() } }
                .onChange(of: intro, initial: true) { _, new in
                    doAfter(new ? 0.3 : 0) { withAnimation(new ? NotchView.intenseAnimation : .smooth) { state.showIntro = new } }
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
                .onChange(of: isKeyWindow) { _, newVal in
                    if !newVal && (!generalSettings.lockNNWhenTyping || !isEditingText) && !notchNook.locked {
                        closeNotch(false, false)
                    }
                }
        }
        
        private func withOptimizedAnimation(_ animation: Animation = .smooth, _ body: @escaping () -> Void) {
            guard !isAnimating else { return }
            isAnimating = true
            withAnimation(animation) {
                body()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                isAnimating = false
            }
        }
        
        internal func handleBriVolKeyPress(_ mediaKey: MediaKey) {
            Task { @MainActor in
                switch mediaKey {
                case .brightnessUp, .brightnessDown:
                    await handleChange(for: .brightness)
                case .volumeUp, .volumeDown, .mute:
                    await handleChange(for: .volume)
                default:
                    break
                }
            }
        }
        
        private func handleChange(for kind: Indicator.Kind) async {
            do {
                // Respond immediately
                let initialValue = try await getValue(for: kind)
                updateIndicator(kind: kind, value: Double(initialValue))
                
                try await Task.sleep(nanoseconds: 50_000_000)
                let newValue = try await getValue(for: kind)
                if abs(newValue - initialValue) > 0.001 {
                    updateIndicator(kind: kind, value: Double(newValue))
                }
            } catch {
                print("Error handling \(kind) change: \(error)")
            }
        }
        
        private func getValue(for kind: Indicator.Kind) async throws -> Float {
            switch kind {
                case .brightness:
                    return try await BrightnessCoordinator.getDisplayBrightness()
                case .volume:
                    return try await SoundCoordinator.getSoundVolume()
            }
        }
        
        private func updateIndicator(kind: Indicator.Kind, value: Double) {
            withOptimizedAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                let indicator = Indicator(kind: kind, value: value)
                notchNook.indicator = indicator
                showIndicator(indicator)
            }
        }
    }
}
