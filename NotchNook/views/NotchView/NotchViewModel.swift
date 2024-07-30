//
//  NotchViewModel.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/06/24.
//

import SwiftUI

@Observable
class NotchViewModel {
    // MARK: - File dropping info
    
    // Current location of file being dragged.
    var droppingCoords: CGPoint?
    
    // Available actions for the type of the file being dragged.
    var availableActions = [Pipeline]()
    
    // Coordinates in points of the available file dropping actions.
    var targetsCoords = [String:CGRect]()
    
    
    // MARK: - Gestures info
    
    var pressing = false
    var hovering = false {
        // Vibrate on hover
        willSet { if !hovering && newValue { vibrate() } }
    }
    
    // Bool that controls if scrolling/dragging gestures are disabled.
    var cancelPan = false
    
    // Amount in pure pts currently being scrolled/dragged.
    var panRawPadding: EdgeInsets = .zero
    
    // A counter made for executing a media action on it's change
    // TODO: This is bad, media actions should be activated on gesture release
    var panGestureCounter = 0
    
    
    // MARK: - General info
    
    // How much should the content downscale.
    // The scale amount is calculated as `1 - scaleDown`.
    var scaleDown: Double = 0
    
    // Simple Bool to track whether NotchView is animating back (closing).
    // Should be enabled at the beggining of close transaction and disabled at the end.
    var animatingBack = false
    
    // Simple Bool to track whether the trial is over or not.
    // TODO: This should be a computed variable
    var trialOver = false
    
    // Simple Bool that controls if intro is being shown.
    // Works in conjunction with Defaults[.intro] Bool.
    // Made for being able to delay intro start bc of app intialization freezes.
    var showIntro = false
    
    // Indicates if finetuning helper is being shown.
    var fineTuningNotchWidth = false
}

// MARK: - Computed variables
extension NotchViewModel {
    
    // File dropping action currently being hovered.
    var hoveredDropTargetID: String? {
        if let droppingCoords,
           let found = targetsCoords.first(where: { $1.contains(droppingCoords) }) {
            return found.key
        }
        return nil
    }
    
    // Actual scroll/drag pan, after some transformations
    // to add resistance to gestures
    var panPadding: EdgeInsets {
        let topInterpolator = interpolatorBuilder([0, 150], value: abs(panRawPadding.top))
        let leadingInterpolator = interpolatorBuilder([0, 150], value: panRawPadding.leading)
        let trailingInterpolator = interpolatorBuilder([0, 150], value: panRawPadding.trailing)
        let bottomInterpolator = interpolatorBuilder([0, 200], value: panRawPadding.bottom)
        
        
        let leading = leadingInterpolator([0, NotchView.maxHPanDrag], true, .linear)
        let trailing = trailingInterpolator([0, NotchView.maxHPanDrag], true, .linear)
        let bottom = bottomInterpolator([0, NotchView.maxVPanDrag], true, .linear)
        
        let decrease = topInterpolator([0, 32], true, .linear)
        
        return .init(
            top: 0,
            leading: ((bottom * 0.5) + leading) - decrease,
            bottom: ((((leading + trailing) / 2) * 0.25) + bottom) - decrease,
            trailing: ((bottom * 0.5) + trailing) - decrease
        )
    }
}
