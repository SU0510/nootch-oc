//
//  Untitled.swift
//  NotchNook
//
//  Created by Lori Montenegro on 11/07/25.
//

import SwiftUI

struct TopBarBackgroundView: View {
    
    var isLeft: Bool
    var panGestureCounter: Int
    var scaleX: Double
    var scaleY: Double
    var panPadding: EdgeInsets
    
    @Environment(\.gestureControlSettings) private var gestureControlSettings
    @Environment(\.notchNook) private var notchNook
    
    var body: some View {
        Group {
            let shouldShowArrows = panPadding.bottom < (NotchView.maxHPanDrag / 3) && gestureControlSettings.controlMedia
            
            switch notchNook.mode {
                case .closed:
                    ArrowForPanningView(
                        x: shouldShowArrows ? (isLeft ? -panPadding.leading : panPadding.trailing) : 0,
                        right: !isLeft,
                        inverted: gestureControlSettings.invertMediaGestures,
                        counter: panGestureCounter
                    )
                    .frame(maxWidth: TopBarView.liveActionWidth, maxHeight: .infinity, alignment: isLeft ? .leading : .trailing)
                case .dragging, .nook, .tray:
                    EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(x: scaleX, y: scaleY, anchor: isLeft ? .trailing : .leading)
        .transition(.scaleAndBlur(anchor: isLeft ? .trailing : .leading))
    }
}
