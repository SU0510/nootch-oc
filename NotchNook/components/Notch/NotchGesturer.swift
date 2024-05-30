//
//  NotchGesturer.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/05/24.
//

import SwiftUI
import Defaults

struct NotchGesturer: View {
    var vibrate: () -> ()
    var hidden: Bool
    var panPadding: EdgeInsets
    @Binding var scaleDown: Double
    @Binding var cancelPan: Bool
    @Binding var panRawPadding: EdgeInsets
    var mode: NotchNook.NotchMode
    var closeNotch: (_ doVibrate: Bool, _ unhover: Bool) -> ()
    var hideNotch: () -> ()
    var openNotch: () -> ()
    var changeTrack: (Bool) -> ()
    
    private var hasMediaLA: Bool { NotchNook.shared.activeLiveActivities.contains(.media) }
    
    @Default(.gestureControlSettings) private var gestureControlSettings
    
    var body: some View {
            ScrollWheelViewRepresentable(onDragChanged: onPan, onDragEnded: onPanEnded)
//            .id(mode.rawValue + cancelPan.description)
    }
    
    // MARK: - Panning gesture functions
    
    func onPanEnded(_ translation: CGSize, _ scrollingPoint: CGPoint, _ velocity: CGSize) {
        cancelPan = false
    }
    
    func onPan(_ translation: CGSize, _ scrollingPoint: CGPoint, _ velocity: CGSize, cancelGesture: () -> ()) {
        if cancelPan || !gestureControlSettings.allowGestures { return }
        
        // Handles scaleDown when swiping up
        if scrollingPoint.y < 0 && // Check if gesture is upwards
                max(panRawPadding.leading, panRawPadding.trailing) < 32 // Checks if there's any horizontal dragging accumulated
        {
            
            // Reacts to swipe in real time
            let interpolate = interpolatorBuilder([0, -150], value: scrollingPoint.y)
            scaleDown += interpolate([0, mode != .closed ? 0.1 : 0.3], true)
            
            // Handles actions
            if scaleDown > (mode != .closed ? 0.03 : 0.1) || // if scaleDown is too big
                    velocity.height < -NotchView.panVelocityTriggerThreshold // or if the gesture velocity is too high
            {
                if mode != .closed {
                    vibrate()
                    closeNotch(true, false)
                } else {
                    vibrate()
                    hideNotch()
                }
            }
        } else {
            // If it fails, reset scaleDown to 0
            if scaleDown != 0 {
                withAnimation(.smooth) { scaleDown = 0 }
            }
        }
        
        // When not opened, only upward gestures work
        if mode != .closed { return }
        
        panRawPadding = .init(
            top: 0,
            leading: panRawPadding.leading + (scrollingPoint.x < 0 ? (abs(scrollingPoint.x) * (hasMediaLA ? 1 : 0.5)) : 0),
            bottom: panRawPadding.bottom + (scrollingPoint.y > 0 ? scrollingPoint.y : 0),
            trailing: panRawPadding.trailing + (scrollingPoint.x > 0 ? (scrollingPoint.x * (hasMediaLA ? 1 : 0.5)) : 0)
        )
        
        // Reset the oposite side on horizontal dragging
        if scrollingPoint.x > 0 {
            withAnimation(.smooth) { panRawPadding.leading = 0 }
        } else if scrollingPoint.x < 0 {
            withAnimation(.smooth) { panRawPadding.trailing = 0 }
        }
              
        // If downwards gesture breaks the threshold, open notch
        if velocity.height > NotchView.panVelocityTriggerThreshold && (gestureControlSettings.controlOpenState || hidden) {
            vibrate()
            openNotch()
        }
        
        if !cancelPan {

            if panPadding.bottom > NotchView.maxVPanDrag && mode == .closed && (gestureControlSettings.controlOpenState || hidden) {
                vibrate()
                openNotch()
            }
            
            // Media forward/backward gestures
            if hasMediaLA && gestureControlSettings.controlMedia {
                if panPadding.bottom < NotchView.maxVPanDrag / 3 {
                    if panPadding.leading > (NotchView.maxHPanDrag) {
                        changeTrack(true)
                    }
                    if panPadding.trailing > (NotchView.maxHPanDrag) {
                        changeTrack(false)
                    }
                }
            }
            
        }
    }
}
