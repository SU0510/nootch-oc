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
    static let windowHeight: Double = 250
    static let mainVSpacing: Double = 8
    static let hoverScale: Double = 1.25
    static let animation: Animation = .bouncy(extraBounce: 0.075)
    static let intenseAnimation: Animation = .bouncy(extraBounce: 0.15)
    static let maxVPanDrag: Double = 14
    static let maxHPanDrag: Double = 24
    static let panVelocityTriggerThreshold: Double = 500
    static func defaultTransition(anchor: UnitPoint, delay: Double = 0.1) -> AnyTransition { AnyTransition.asymmetric(insertion: .scaleAndBlur(anchor: anchor).animation(.smooth(duration: 0.35).delay(delay)), removal: .scaleAndBlur(anchor: .top).animation(.smooth(duration: 0.2))) }
    static let defaultTransition = NotchView.defaultTransition(anchor: .top)

    @State internal var state = NotchViewModel()
    @Environment(\.notchSize) internal var notchSize
    @Environment(\.screenSize) internal var screenSize
    @Environment(\.notchNook) internal var notchNook
    @Environment(\.generalSettings) internal var generalSettings
    @Default(.intro) internal var intro
    @Default(.license) internal var license
    @Default(.trialInitialTime) internal var trialInitialTime
    
    var actualScale: Double { (state.hovering && !state.pressing && (notchNook.mode == .closed) ? NotchView.hoverScale : 1) - state.scaleDown }
    var disableNotchNook: Bool { notchSize.height == 0 && !generalSettings.enableOnNonNotchScreens }
    
    var body: some View {        
        VStack(alignment: .center, spacing: NotchView.mainVSpacing) {
            if !disableNotchNook {
                if intro && state.showIntro {
                    IntroView()
                } else if !intro {
                    
                    if license != nil || !state.trialOver {
                        TopBarView(
                            panGestureCounter: state.panGestureCounter,
                            scale: actualScale,
                            panPadding: state.panPadding,
                            hide: notchNook.hidden
                        )
                    }
                    
                    Group {
                        if license == nil && (trialInitialTime == nil || state.trialOver) && notchNook.mode != .closed {
                            LicenseStateView()
                        } else {
                            switch notchNook.mode {
                                case .closed: EmptyView()
                                case .dragging: DropArea(targetsCoords: $state.targetsCoords, availableActions: state.availableActions, hoveredDropTargetID: state.hoveredDropTargetID)
                                case .nook: NookView()
                                case .tray: TrayView(hovered: false, full: true)
                            }
                        }
                    }
                    .scaleEffect(actualScale, anchor: .top)
                    .transition(NotchView.defaultTransition)
                }
            }
            if state.fineTuningNotchWidth {
                FineTuningView(fineTuningValue: generalSettings.notchWidthFineTune)
            }
        }
        .blur(radius: state.scaleDown * 100)
        .fixedSize(horizontal: true, vertical: false)
        .frame(
            minWidth: notchSize.height == 0 ? generalSettings.handleSize.width : notchSize.width + generalSettings.notchWidthFineTune,
            minHeight: disableNotchNook ? 0 : notchSize.height == 0 ? generalSettings.handleSize.height : notchSize.height
        )
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
}
