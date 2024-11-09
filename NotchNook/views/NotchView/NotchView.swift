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
    
    @State internal var viewModel = NotchViewModel()
    @State private var isFullScreen = false

    @Environment(\.notchSize) internal var notchSize
    @Environment(\.screenSize) internal var screenSize
    var screen: NSScreen
    @Environment(\.notchNook) internal var notchNook
    @Environment(\.generalSettings) internal var generalSettings
    @Default(.intro) internal var intro
    @Default(.license) internal var license
    @Default(.trialInitialTime) internal var trialInitialTime
    @Environment(\.showIndicator) var showIndicator

    private var isNonNotch: Bool {
        notchSize.height == 0
    }
    
    private var isNotchedScreen: Bool {
        notchSize.height > 0
    }
    
    private var isDisabled: Bool {
        (isNonNotchAndDisabled || isDisabledDueToFullScreen) && (!shouldShowIndicator)
    }
    
    private var shouldShowIndicator: Bool {
        notchNook.indicator != nil && NSScreen.main == screen
    }
    
    private var isNonNotchAndDisabled: Bool {
        isNonNotch && !generalSettings.enableOnNonNotchScreens
    }
    
    private var isDisabledDueToFullScreen: Bool {
        switch generalSettings.showInFullscreen {
            case .allMonitors:
                return false
            case .notchedScreens:
                return isNonNotch && isFullScreen
            case .never:
                return isFullScreen
        }
    }
    
    private var isHeightFineTuning: Bool {
        viewModel.notchState == .fineTuningHeight
    }
    
    var body: some View {
        let nonNotchWidth = generalSettings.handleSize.width
        let nnMinWidth = isNonNotch ? nonNotchWidth : notchSize.width + generalSettings.notchWidthFineTune
        let nonNotchHeight = generalSettings.transparentHandle ? 0 : generalSettings.handleSize.height
        let nnMinHeight = isDisabled || isHeightFineTuning ? 0 : isNonNotch ? nonNotchHeight : notchSize.height
        
        mainContent
            .blur(radius: viewModel.scaleDown * 150)
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: isHeightFineTuning ? nnMinWidth + 40 : nnMinWidth, minHeight: nnMinHeight)
            .padding((notchNook.mode == .closed ? viewModel.panPadding : .zero) + standardPadding)
            .coordinateSpace(name: "drop-zone")
            .modifier(ShapeModifier(state: viewModel))
            .modifier(LockedIndicatorModifier(state: viewModel))
            .offset(x: (-viewModel.panPadding.leading + viewModel.panPadding.trailing) / 3)
            .modifier(AnimationsModifier(disableNotchNook: isDisabled))
            .modifier(GesturesModifier(state: viewModel, disableNotchNook: isDisabled))
            .frame(width: screenSize.width, height: NotchView.windowHeight, alignment: .top)
            .modifier(EnvironmentsModifier(state: viewModel))
            .modifier(SideEffectsModifier(viewModel: viewModel, showIndicator: showIndicator, screen: screen))
            .onChange(of: FullscreenMonitor.shared.fullScreenStateDict) { _, updatedFullscreenDict in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isFullScreen = updatedFullscreenDict[screen] ?? false
                    viewModel.update(settings: generalSettings, isNonNotch: isNonNotch, isFullScreen: isFullScreen)
                }
            }
            .onAppear {
                isFullScreen = FullscreenMonitor.shared.fullScreenStateDict[screen] ?? false
                viewModel.update(settings: generalSettings, isNonNotch: isNonNotch, isFullScreen: isFullScreen)
            }
            .onChange(of: notchNook.indicator) {
                if shouldShowIndicator {
                    viewModel.notchState = .showingHUDIndicator
                }
            }
    }
    
    private var mainContent: some View {
        Group {
            switch viewModel.notchState {
                case .showingHUDIndicator:
                    if let indicator = notchNook.indicator {
                        IndicatorView(indicator: indicator)
                            .transition(NotchView.defaultTransition)
                    }
                case .disabled:
                    EmptyView()
                case .showingIntro:
                    IntroView()
                case .fineTuningWidth:
                    VStack(alignment: .center, spacing: NotchView.mainVSpacing) {
                        TopBarSpacerView(height: notchSize.height)
                        
                        if isNotchedScreen {
                            WidthFineTuningView(fineTuningValue: generalSettings.notchWidthFineTune)
                        }
                    }
                case .standardContent:
                    nonIntroContent
                    
                case .fineTuningHeight:
                    if isNotchedScreen {
                        HeightFineTuningView(fineTuningValue: generalSettings.notchHeightFineTune)
                            .frame(width: 40, alignment: .leading)
                            .offset(x: -100)
                    }
            }
        }
    }
    
    @ViewBuilder
    private var nonIntroContent: some View {
        topBarContent
            .opacity(notchNook.indicator == nil ? 1 : 0)
        
        Group {
            if license == nil && (trialInitialTime == nil || viewModel.trialOver) && notchNook.mode != .closed {
                LicenseStateView()
            } else {
                nookModeContent
            }
        }
        .transition(NotchView.defaultTransition)
        .scaleEffect(x: actualScaleX, y: actualScaleY, anchor: .init(x: 0.5, y: -0.25))
    }
    
    @ViewBuilder
    private var topBarContent: some View {
        if license != nil || (!viewModel.trialOver && trialInitialTime != nil) {
            TopBarView(
                panGestureCounter: viewModel.panGestureCounter,
                scaleX: actualScaleX,
                scaleY: actualScaleY,
                panPadding: viewModel.panPadding,
                isHidden: notchNook.hidden
            )
            .equatable()
        }
    }
    
    @ViewBuilder
    private var nookModeContent: some View {
        switch notchNook.mode {
        case .closed:
            EmptyView()
        case .dragging:
            DropArea(targetsCoords: $viewModel.targetsCoords, availableActions: viewModel.availableActions, hoveredDropTargetID: viewModel.hoveredDropTargetID)
        case .nook:
            NookView()
        case .tray:
            TrayView(hovered: false, full: true)
        }
    }
}
