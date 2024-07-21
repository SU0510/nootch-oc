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
    
    private var hasMediaLA: Bool { ActiveLiveActivitiesManager.shared.activeLiveActivities.contains(.media) }
    
    @Environment(\.gestureControlSettings) private var gestureControlSettings
    
    var body: some View {
            ScrollWheelViewRepresentable(onDragChanged: onPan, onDragEnded: onPanEnded)
    }
    
    // MARK: - Panning gesture functions
    
    func onPanEnded(_ translation: CGSize, _ scrollingPoint: CGPoint, _ velocity: CGSize) {
        state.cancelPan = false
    }
    
    func onPan(_ translation: CGSize, _ scrollingPoint: CGPoint, _ velocity: CGSize, cancelGesture: () -> ()) {
        if state.cancelPan || !gestureControlSettings.allowGestures { return }
        
        if // Handles scaleDown when swiping up
            scrollingPoint.y < 0 && // Check if gesture is upwards
                max(state.panRawPadding.leading, state.panRawPadding.trailing) < 32 // There cannot be any horizontal dragging accumulated
        {
            
            // Reacts to swipe in real time
            // Interpolates raw scrolling amount into incremental
            // scaleDown of contents inside the notch
            let interpolate = interpolatorBuilder([0, -150], value: scrollingPoint.y)
            state.scaleDown += interpolate([0, notchNook.mode != .closed ? 0.1 : 0.3], true, .linear)
            
            if // Handles actions
                state.scaleDown > (notchNook.mode != .closed ? 0.03 : 0.1) || // if scaleDown is too big
                    velocity.height < -NotchView.panVelocityTriggerThreshold // or if the gesture velocity is too high
            {
                if notchNook.mode != .closed {
                    vibrate()
                    closeNotch(true, false)
                } else if !notchNook.hidden && !ActiveLiveActivitiesManager.shared.activeLiveActivities.isEmpty {
                    vibrate()
                    hideNotch()
                }
            }
        } else {
            // If it fails, reset scaleDown to 0
            if state.scaleDown != 0 {
                withAnimation(.smooth) { state.scaleDown = 0 }
            }
        }
        
        // When not opened, only upward gestures work
        if notchNook.mode != .closed { return }
        
        state.panRawPadding = .init(
            top: 0,
            leading: state.panRawPadding.leading + (scrollingPoint.x < 0 ? (abs(scrollingPoint.x) * (hasMediaLA ? 1 : 0.5)) : 0),
            bottom: state.panRawPadding.bottom + (scrollingPoint.y > 0 ? scrollingPoint.y : 0),
            trailing: state.panRawPadding.trailing + (scrollingPoint.x > 0 ? (scrollingPoint.x * (hasMediaLA ? 1 : 0.5)) : 0)
        )
        
        // Reset the oposite side on horizontal dragging
        if scrollingPoint.x > 0 {
            withAnimation(.smooth) { state.panRawPadding.leading = 0 }
        } else if scrollingPoint.x < 0 {
            withAnimation(.smooth) { state.panRawPadding.trailing = 0 }
        }

        // If downwards gesture breaks the threshold, open notch
        if velocity.height > NotchView.panVelocityTriggerThreshold && (gestureControlSettings.controlOpenState || notchNook.hidden) {
            vibrate()
            openNotch(.nook)
        }
        
        if !state.cancelPan {

            if state.panPadding.bottom > NotchView.maxVPanDrag && notchNook.mode == .closed && (gestureControlSettings.controlOpenState || notchNook.hidden) {
                vibrate()
                openNotch(.nook)
            }
            
            // Media forward/backward gestures
            if hasMediaLA && gestureControlSettings.controlMedia {
                if state.panPadding.bottom < NotchView.maxVPanDrag / 3 {
                    if state.panPadding.leading > (NotchView.maxHPanDrag) {
                        changeTrack(prev: true)
                    }
                    if state.panPadding.trailing > (NotchView.maxHPanDrag) {
                        changeTrack(prev: false)
                    }
                }
            }
            
        }
    }
    
    
    // MARK: - Util functions
    
    func changeTrack(prev: Bool) {
        withAnimation(.smooth) {
            vibrate()
            state.panRawPadding = .zero
            state.cancelPan = true
            if prev { state.panGestureCounter -= 1 } else { state.panGestureCounter += 1 }
        }
    }
}
