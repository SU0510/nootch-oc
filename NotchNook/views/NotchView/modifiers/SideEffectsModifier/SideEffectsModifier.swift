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
        @Environment(\.notchSize) internal var notchSize
        
        @State private var hasAppeared: Bool = false
        @State private var isAnimating: Bool = false
        
        func body(content: Content) -> some View {
            content
                .onAppear {
                    if !hasAppeared {
                        hasAppeared = true
                        Task {
                            await performInitialSetup()
                        }
                    }
                }
                .onChange(of: liveActivitiesSettings.enableHUDReplacement) {
                    startBriVolKeyListener()
                }
                .onChange(of: liveActivitiesSettings.enabledLiveActivities) { old, new in
                    if !old.contains(.calendar) && new.contains(.calendar) {
                        Task {
                            try? await CalendarManager.shared.fetchEventsForDaysOffset(CalendarManager.numberOfDaysToDisplay)
                        }
                    }
                }
                .onChange(of: state.hoveredDropTargetID) { old, new in
                    if old != new && new != nil {
                        Task { @MainActor in
                            vibrate()
                        }
                    }
                }
                .onChange(of: intro) { _, new in
                    withOptimizedAnimation {
                        state.showIntro = new
                    }
                }
                .onChange(of: generalSettings.notchWidthFineTune) { _, _ in
                    withOptimizedAnimation {
                        state.fineTuningNotchWidth = true
                    }
                }
                .onChange(of: isKeyWindow) { _, newVal in
                    if !newVal && (!generalSettings.lockNNWhenTyping || !isEditingText) && !notchNook.locked {
                        closeNotch(false, false)
                    }
                }
                .onChange(of: state.panRawPadding) { _, _ in
                    withOptimizedAnimation {
                        state.panRawPadding = .zero
                    }
                }
                .onChange(of: state.scaleDown) { _ in
                    withOptimizedAnimation {
                        state.scaleDown = 0
                    }
                }
        }
        
        private func performInitialSetup() async {
            await MainActor.run {
                checkForUpdates()
                resetTrialAndHandleChangelog()
                insertUpdateLAIfOldVersion()
                startBriVolKeyListener()
                fetchEvents()
            }
        }
        
        private func withOptimizedAnimation(_ animation: Animation = .smooth, _ body: @escaping () -> Void) {
            guard !isAnimating else { return }
            isAnimating = true
            withAnimation(animation) {
                body()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isAnimating = false
            }
        }
        
        internal func handleBriVolKeyPress(_ mediaKey: MediaKey) {
            guard liveActivitiesSettings.enableHUDReplacement else {
                VolumeAndBrightnessListener.shared.stop()
                return
            }
            
            Task { @MainActor in
                switch mediaKey {
                case .brightnessUp, .brightnessDown:
                    await handleBrightnessChange()
                case .volumeUp, .volumeDown, .mute:
                    await handleVolumeChange()
                }
            }
        }
        
        private func handleBrightnessChange() async {
            do {
                // Delay to ensure the brightness has changed
                try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                
                let newBrightness = try await BrightnessCoordinator.getDisplayBrightness()
                withOptimizedAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    notchNook.indicator = .init(kind: .brightness, value: Double(newBrightness))
                }
            } catch {
                print("Error fetching brightness: \(error)")
            }
        }

        private func handleVolumeChange() async {
            do {
                // Delay to ensure the volume has changed
                try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                
                let newVolume = try await SoundCoordinator.getSoundVolume()
                withOptimizedAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    notchNook.indicator = .init(kind: .volume, value: Double(newVolume))
                }
            } catch {
                print("Failed to get volume: \(error)")
            }
        }
    }
}
