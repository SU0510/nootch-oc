//
//  NotchGesturer.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/05/24.
//

import SwiftUI
import Defaults

struct NotchGesturer: View {
    var state: NotchViewModel
    
    @Environment(\.notchNook) private var notchNook
    @Environment(\.closeNotch) private var closeNotch
    @Environment(\.hideNotch) private var hideNotch
    @Environment(\.openNotch) private var openNotch
    @Environment(\.gestureControlSettings) private var gestureControlSettings
    
    @State private var hasMediaLA: Bool = false
    
    var body: some View {
        ScrollWheelViewRepresentable(onDragChanged: onPan, onDragEnded: onPanEnded)
            .onAppear {
                hasMediaLA = ActiveLiveActivitiesManager.shared.activeLiveActivities.contains(.media)
            }
    }
    
    // MARK: - Panning gesture functions
    
    func onPanEnded(_ translation: CGSize, _ scrollingPoint: CGPoint, _ velocity: CGSize) {
        state.cancelPan = false
    }
    
    func onPan(_ translation: CGSize, _ scrollingPoint: CGPoint, _ velocity: CGSize, cancelGesture: () -> Void) {
        guard !state.cancelPan && gestureControlSettings.allowGestures else { return }
        
        handleVerticalPan(scrollingPoint: scrollingPoint, velocity: velocity)
        
        if notchNook.mode == .closed {
            handleHorizontalPan(scrollingPoint: scrollingPoint, velocity: velocity)
        }
    }
    
    private func handleVerticalPan(scrollingPoint: CGPoint, velocity: CGSize) {
        if scrollingPoint.y < 0 && max(state.panRawPadding.leading, state.panRawPadding.trailing) < 32 {
            updateScaleDown(scrollingPoint: scrollingPoint)
            checkForVerticalAction(velocity: velocity)
        } else if state.scaleDown != 0 {
            withAnimation(.smooth) { state.scaleDown = 0 }
        }
        
        checkForOpenAction(velocity: velocity)
    }
    
    private func updateScaleDown(scrollingPoint: CGPoint) {
        let interpolate = interpolatorBuilder([0, -150], value: scrollingPoint.y)
        state.scaleDown += interpolate([0, notchNook.mode != .closed ? 0.1 : 0.3], true, .linear)
    }
    
    private func checkForVerticalAction(velocity: CGSize) {
        if state.scaleDown > (notchNook.mode != .closed ? 0.03 : 0.1) || velocity.height < -NotchView.panVelocityTriggerThreshold {
            if notchNook.mode != .closed {
                vibrate()
                closeNotch(true, false)
            } else if !notchNook.hidden && !ActiveLiveActivitiesManager.shared.activeLiveActivities.isEmpty {
                vibrate()
                hideNotch()
            }
        }
    }
    
    private func checkForOpenAction(velocity: CGSize) {
        if velocity.height > NotchView.panVelocityTriggerThreshold && (gestureControlSettings.controlOpenState || notchNook.hidden) {
            vibrate()
            openNotch(.nook)
        }
    }
    
    private func handleHorizontalPan(scrollingPoint: CGPoint, velocity: CGSize) {
        updatePanRawPadding(scrollingPoint: scrollingPoint)
        
        if scrollingPoint.x > 0 {
            withAnimation(.smooth) { state.panRawPadding.leading = 0 }
        } else if scrollingPoint.x < 0 {
            withAnimation(.smooth) { state.panRawPadding.trailing = 0 }
        }
        
        checkForMediaActions()
        checkForOpenActionOnVerticalPan()
    }
    
    private func updatePanRawPadding(scrollingPoint: CGPoint) {
        state.panRawPadding.leading += scrollingPoint.x < 0 ? (abs(scrollingPoint.x) * (hasMediaLA ? 1 : 0.5)) : 0
        state.panRawPadding.trailing += scrollingPoint.x > 0 ? (scrollingPoint.x * (hasMediaLA ? 1 : 0.5)) : 0
        state.panRawPadding.bottom += scrollingPoint.y > 0 ? scrollingPoint.y : 0
    }
    
    private func checkForMediaActions() {
        if hasMediaLA && gestureControlSettings.controlMedia && state.panPadding.bottom < NotchView.maxVPanDrag / 3 {
            if state.panPadding.leading > NotchView.maxHPanDrag {
                changeTrack(prev: true)
            }
            if state.panPadding.trailing > NotchView.maxHPanDrag {
                changeTrack(prev: false)
            }
        }
    }
    
    private func checkForOpenActionOnVerticalPan() {
        if state.panPadding.bottom > NotchView.maxVPanDrag && notchNook.mode == .closed && (gestureControlSettings.controlOpenState || notchNook.hidden) {
            vibrate()
            openNotch(.nook)
        }
    }
    
    private func changeTrack(prev: Bool) {
        withAnimation(.smooth) {
            vibrate()
            state.panRawPadding = .zero
            state.cancelPan = true
            if prev { state.panGestureCounter -= 1 } else { state.panGestureCounter += 1 }
        }
    }
}
