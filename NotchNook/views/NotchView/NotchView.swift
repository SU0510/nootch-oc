//
//  Notch.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI
import Defaults
import Cocoa
import UniformTypeIdentifiers

struct NotchView: View {
    @State internal var state = NotchViewModel()
    @Environment(\.notchSize) private var notchSize
    @Environment(\.screenSize) private var screenSize
    @Environment(\.notchNook) var notchNook
    @Environment(\.generalSettings) var generalSettings
    @Default(.intro) private var intro
    @Default(.license) private var license
    @Default(.trialInitialTime) private var trialInitialTime
    private var disableNotchNook: Bool {
        notchSize.height == 0 && !generalSettings.enableOnNonNotchScreens
    }
    
    var body: some View {
        let nnMinWidth = notchSize.height == 0 ? generalSettings.handleSize.width : notchSize.width + generalSettings.notchWidthFineTune
        let nnMinHeight = disableNotchNook ? 0 : notchSize.height == 0 ? generalSettings.handleSize.height : notchSize.height
        
        VStack(alignment: .center, spacing: NotchView.mainVSpacing) {
            mainContent
        }
        .blur(radius: state.scaleDown * 150)
        .fixedSize(horizontal: true, vertical: false)
        .frame(minWidth: nnMinWidth, minHeight: nnMinHeight)
        .padding((notchNook.mode == .closed ? state.panPadding : .zero) + standardPadding)
        .coordinateSpace(name: "drop-zone")
        .modifier(ShapeModifier(state: state))
        .modifier(LockedIndicatorModifier(state: state))
        .offset(x: (-state.panPadding.leading + state.panPadding.trailing) / 3)
        .modifier(AnimationsModifier(disableNotchNook: disableNotchNook))
        .modifier(GesturesModifier(state: state, disableNotchNook: disableNotchNook))
        .frame(width: screenSize.width, height: NotchView.windowHeight, alignment: .top)
        .modifier(SideEffectsModifier(state: state))
        .modifier(EnvironmentsModifier(state: state))
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if let indicator = notchNook.indicator {
            IndicatorView(indicator: indicator)
                .transition(NotchView.defaultTransition)
        } else {
            
            if !disableNotchNook {
                if (intro && state.showIntro) || state.showIntro {
                    IntroView()
                } else if !intro {
                    nonIntroContent
                }
            }
            
            if state.fineTuningNotchWidth {
                FineTuningView(fineTuningValue: generalSettings.notchWidthFineTune)
            }
        }
    }
    
    @ViewBuilder
    private var topBarContent: some View {
        if license != nil || !state.trialOver {
            TopBarView(
                panGestureCounter: state.panGestureCounter,
                scaleX: actualScaleX,
                scaleY: actualScaleY,
                panPadding: state.panPadding,
                hide: notchNook.hidden
            )
            .equatable()
        }
    }
    
    @ViewBuilder
    private var indicatorContent: some View {
        if let indicator = notchNook.indicator {
            IndicatorView(indicator: indicator)
                .transition(NotchView.defaultTransition)
        }
    }
    
    @ViewBuilder
    private var nonIntroContent: some View {
        
        topBarContent
            .opacity(notchNook.indicator == nil ? 1 : 0)
        
        Group {
            if license == nil && (trialInitialTime == nil || state.trialOver) && notchNook.mode != .closed {
                LicenseStateView()
            } else {
                nookModeContent
            }
        }
        .transition(NotchView.defaultTransition)
        .scaleEffect(x: actualScaleX, y: actualScaleY, anchor: .init(x: 0.5, y: -0.25))
    }
    
    @ViewBuilder
    private var nookModeContent: some View {
        switch notchNook.mode {
        case .closed:
            EmptyView()
        case .dragging:
            DropArea(targetsCoords: $state.targetsCoords, availableActions: state.availableActions, hoveredDropTargetID: state.hoveredDropTargetID)
        case .nook:
            NookView()
        case .tray:
            TrayView(hovered: false, full: true)
        }
    }
}
