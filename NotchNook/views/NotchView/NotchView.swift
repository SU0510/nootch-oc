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
    static let mainVSpacing: Double = 8
    static let hoverScale: Double = 1.25
    static let animation: Animation = .bouncy(extraBounce: 0.075)
    static let intenseAnimation: Animation = .bouncy(extraBounce: 0.15)
    static let maxVPanDrag: Double = 14
    static let maxHPanDrag: Double = 24
    static let panVelocityTriggerThreshold: Double = 500
    static func defaultTransition(anchor: UnitPoint, delay: Double = 0.1) -> AnyTransition { AnyTransition.asymmetric(insertion: .scaleAndBlur(anchor: anchor).animation(.smooth(duration: 0.35).delay(delay)), removal: .scaleAndBlur(anchor: .top).animation(.smooth(duration: 0.2))) }
    static let defaultTransition = NotchView.defaultTransition(anchor: .top)
    
    @State internal var droppingCoords: CGPoint?
    @State internal var pressing = false
    @State internal var hovering = false {
        willSet { if !hovering && newValue { vibrate() } }
    }
    @State internal var cancelPan = false
    @State internal var availableActions = [DropAction]()
    @State internal var targetsCoords = [String:CGRect]()
    @State internal var panRawPadding: EdgeInsets = .zero
    @State internal var scaleDown: Double = 0
    @State internal var panGestureCounter = 0
    @State internal var trialOver = false
    @State internal var showIntro = false
    @State internal var animatingBack = false
    @State internal var fineTuningNotchWidth = false
    @Namespace internal var ns
    @Environment(\.notchSize) internal var notchSize
    @Environment(\.screenSize) internal var screenSize
    @Environment(\.openSettings) internal var openSettings
    @Environment(\.sparkleManager) internal var sparkleManager
    @Environment(\.showChangelog) internal var showChangelog
    @Environment(\.notchNook) internal var notchNook
    @Environment(\.tray) internal var tray
    @Environment(\.canBecomeKey) internal var canBecomeKey
    @Environment(\.makeKeyWindow) internal var makeKeyWindow
    @Environment(\.resignFirstResponder) internal var resignFirstResponder
    @Environment(\.focusFrontmostWindow) internal var focusFrontmostWindow
    @Environment(\.isEditingText) internal var isEditingText
    @Default(.lastBuildNumber) internal var lastBuildNumber
    @Default(.intro) internal var intro
    @Default(.license) internal var license
    @Default(.generalSettings) internal var generalSettings
    @Default(.liveActivitiesSettings) internal var liveActivitiesSettings
    @Default(.nookSettings) internal var nookSettings
    @Default(.trialInitialTime) internal var trialInitialTime
    
    var body: some View {
        let actualScale = (hovering && !pressing && (mode == .closed) ? NotchView.hoverScale : 1) - scaleDown
        let disableNotchNook = notchSize.height == 0 && !generalSettings.enableOnNonNotchScreens
        
        VStack(alignment: .center, spacing: NotchView.mainVSpacing) {
            if !disableNotchNook {
                if intro && showIntro {
                    IntroView()
                } else if !intro {
                    
                    if license != nil || !trialOver {
                        TopBarView(
                            panGestureCounter: panGestureCounter,
                            scale: actualScale,
                            panPadding: panPadding,
                            hide: notchNook.hidden
                        )
                    }
                    
                    Group {
                        if license == nil && (trialInitialTime == nil || trialOver) && mode != .closed {
                            LicenseStateView()
                        } else {
                            switch mode {
                                case .closed: EmptyView()
                                case .dragging: DropArea(targetsCoords: $targetsCoords, availableActions: availableActions, hoveredDropTargetID: hoveredDropTargetID)
                                case .nook: NookView()
                                case .tray: TrayView(hovered: false, full: true)
                            }
                        }
                    }
                    .scaleEffect(actualScale, anchor: .top)
                    .transition(NotchView.defaultTransition)
                }
            }
            if fineTuningNotchWidth {
                FineTuningView(fineTuningValue: generalSettings.notchWidthFineTune)
            }
        }
        .blur(radius: scaleDown * 100)
        .fixedSize(horizontal: true, vertical: false)
        .frame(
            minWidth: notchSize.height == 0 ? generalSettings.handleSize.width : notchSize.width + generalSettings.notchWidthFineTune,
            minHeight: disableNotchNook ? 0 : notchSize.height == 0 ? generalSettings.handleSize.height : notchSize.height
        )
        .padding((mode == .closed ? panPadding : .zero) + standardPadding)
        .coordinateSpace(name: "drop-zone")
        .mask(alignment: .top) { notchShapeView(shadow: false, transparentHandle: false) }
        .background {
            NotchGesturer(
                hidden: notchNook.hidden,
                panPadding: panPadding,
                scaleDown: $scaleDown,
                cancelPan: $cancelPan,
                panRawPadding: $panRawPadding,
                mode: mode,
                closeNotch: {closeNotch(vibrate: $0, unhover: $1)},
                hideNotch: hideNotch,
                openNotch: { openNotch() },
                changeTrack: { changeTrack(prev: $0) }
            )
        }
        .contentShape(NotchShape(notchSize: notchSize))
        .overlay(alignment: .bottomLeading) {
            if mode != .closed && mode != .dragging {
                LockedIndicatorView(
                    locked: notchNook.locked,
                    toggleLock: { notchNook.locked.toggle() },
                    typing: isEditingText
                )
//                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .scaleEffect(actualScale, anchor: .topTrailing)
                    .blur(radius: scaleDown * 100)
            }
        }
        .background(alignment: .top) {
            ZStack {
                Color.hitBox
                
                let showFileDropView = mode == .closed || mode == .dragging
                if showFileDropView {
                    FileDropView(dropEntered: dropEntered, dropUpdated: dropUpdated, performDrop: performDrop, dropExited: dropExited)
                }
                
                notchShapeView()
            }
        }
        .offset(x: (-panPadding.leading + panPadding.trailing) / 3)
        .allowsHitTesting(!disableNotchNook)
        .animation(.smooth, value: disableNotchNook)
        .animation(.smooth(extraBounce: 0.15), value: liveActivitiesSettings)
        .animation(.smooth(extraBounce: 0.15), value: intro)
        .onTapGesture { 
            resignFirstResponder()
            if nookSettings.enabled && mode == .closed && !showIntro { openNotch() }
        }
        .onLongPressGesture(minimumDuration: 0.3, maximumDistance: 30, perform: {}, onPressingChanged: onLongPress)
        .onHover(perform: onHover)
        .contextMenu {
            Button("Open Settings") { openSettings(nil) }
            Button("Quit NotchNook") { NSApp.terminate(nil) }
        }
        .frame(width: screenSize.width, height: 215, alignment: .top)
        .onAppear {
            checkForUpdates()
            resetTrialAndHandleChangelog()
            insertUpdateLAIfOldVersion()
            fetchEvents()
        }
        .onChange(of: liveActivitiesSettings.enabledLiveActivities, initial: true) { old, new in
            if !old.contains(.calendar) && new.contains(.calendar) {
                Task { try? await CalendarManager.shared.fetchEventsForDaysOffset(CalendarWidgetView.showingDatesCount) }
            }
        }
        .onChange(of: hoveredDropTargetID) { if $0 != $1 && $1 != nil { vibrate() } }
        .onChange(of: intro, initial: true) { _, new in
            doAfter(0.3) { withAnimation(NotchView.intenseAnimation) { showIntro = new } }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            closeNotch(unhover: true)
        }
        .onChange(of: generalSettings.notchWidthFineTune) { _, _ in
            if !fineTuningNotchWidth {
                withAnimation(NotchView.intenseAnimation) { fineTuningNotchWidth = true }
            }
        }
        .onChangeDebounced(of: generalSettings.notchWidthFineTune, delay: 2) { _ in
            withAnimation(NotchView.intenseAnimation) { fineTuningNotchWidth = false }
        }
        .onChangeDebounced(of: panRawPadding, delay: 0.05) { _ in
            withAnimation(.smooth) { panRawPadding = .zero }
        }
        .onChangeDebounced(of: scaleDown, delay: 0.05) { _ in
            withAnimation(.smooth) { scaleDown = 0 }
        }
        .environment(\.namespace, ns)
        .environment(\.trialOver, trialOver)
        .preferredColorScheme(.dark)
        .transformEnvironment(\.notchSize) { $0.width += generalSettings.notchWidthFineTune }
    }
}
