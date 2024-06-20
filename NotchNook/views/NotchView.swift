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
    static let openInnerPadding: Double = 16
    static let hoverScale: Double = 1.25
    static let animation: Animation = .bouncy(extraBounce: 0.075)
    static let maxVPanDrag: Double = 14
    static let maxHPanDrag: Double = 24
    static let panVelocityTriggerThreshold: Double = 500
    static func defaultTransition(anchor: UnitPoint, delay: Double = 0.1) -> AnyTransition { AnyTransition.asymmetric(insertion: .scaleAndBlur(anchor: anchor).animation(.smooth(duration: 0.35).delay(delay)), removal: .scaleAndBlur(anchor: .top).animation(.smooth(duration: 0.2))) }
    static let defaultTransition = NotchView.defaultTransition(anchor: .top)
    
    @State private var droppingCoords: CGPoint?
    @State private var pressing = false
    @State private var hovering = false
    @State private var cancelPan = false
    @State private var availableActions = [DropAction]()
    @State private var targetsCoords = [String:CGRect]()
    @State private var panRawPadding: EdgeInsets = .zero
    @State private var scaleDown: Double = 0
    @State private var hide = false
    @State private var hideTimer: Timer?
    @State private var panGestureCounter = 0
    @State private var trialOver = false
    @State private var showIntro = false
    @Namespace private var ns
    @Environment(\.notchHeight) private var notchHeight
    @Environment(\.screenSize) private var screenSize
    @Environment(\.screenID) private var screenID
    @Environment(\.openSettings) private var openSettings
    @Default(.intro) private var intro
    @Default(.license) private var license
    @Default(.generalSettings) private var generalSettings
    @Default(.liveActivitiesSettings) private var liveActivitiesSettings
    @Default(.trialInitialTime) private var trialInitialTime
    
    var mode: NotchNook.NotchMode {
        guard let found = NotchNook.shared.mode[screenID] else {
            NotchNook.shared.mode[screenID] = .closed
            return .closed
        }
        return found
    }
    
    var hoveredDropTargetID: String? {
        if let droppingCoords,
           let found = targetsCoords.first(where: { $1.contains(droppingCoords) }) {
            return found.key
        }
        return nil
    }
    
    var panPadding: EdgeInsets {
        let topInterpolator = interpolatorBuilder([0, 150], value: abs(panRawPadding.top))
        let leadingInterpolator = interpolatorBuilder([0, 150], value: panRawPadding.leading)
        let trailingInterpolator = interpolatorBuilder([0, 150], value: panRawPadding.trailing)
        let bottomInterpolator = interpolatorBuilder([0, 200], value: panRawPadding.bottom)
        
        
        let leading = leadingInterpolator([0, Self.maxHPanDrag], true)
        let trailing = trailingInterpolator([0, Self.maxHPanDrag], true)
        let bottom = bottomInterpolator([0, Self.maxVPanDrag], true)
        
        let decrease = topInterpolator([0, 32], true)
        
        return .init(
            top: 0,
            leading: ((bottom * 0.5) + leading) - decrease,
            bottom: ((((leading + trailing) / 2) * 0.25) + bottom) - decrease,
            trailing: ((bottom * 0.5) + trailing) - decrease
        )
    }
    
    var standardPadding: EdgeInsets {
        var pad: Double = 0
        if mode == .closed {
            if hovering {
                if pressing {
                    pad = 4
                } else {
                    pad = 8
                }
            } else {
                pad = 0
            }
        } else {
            pad = Self.openInnerPadding
        }
        return EdgeInsets(top: 0, leading: pad, bottom: pad, trailing: pad)
    }
    
    func checkTrialOver() {
        if license == nil {
            if let trialInitialTime, (((Date().timeIntervalSince1970 - trialInitialTime) / 60) / 60) > LicenseManager.trialDurationInHours {
                if !trialOver { trialOver = true }
            } else {
                if trialOver { trialOver = false }
            }
        } else {
            if trialInitialTime != nil { trialInitialTime = nil }
            if trialOver { trialOver = false }
        }
    }
    
    @ViewBuilder func shapeView(shadow: Bool? = nil, transparentHandle: Bool? = nil) -> some View {
        GeometryReader { geo in
            ShadowedNotchShapeView(shadow: shadow ?? (mode != .closed || hovering), transparentHandle: transparentHandle ?? generalSettings.transparentHandle)
                .frame(width: geo.size.width * (1 - scaleDown), height: geo.size.height * (1 - scaleDown), alignment: .top)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }
    
    var body: some View {
        let filesShelfCount = Shelf.shared.files.count
        let isShelfEmpty = filesShelfCount == 0
        let actualScale = (hovering && !pressing && (mode == .closed) ? NotchView.hoverScale : 1) - scaleDown
        
        VStack(alignment: .center, spacing: NotchView.mainVSpacing) {
            
            if intro && showIntro {
                IntroView()
            } else if !intro {
                
                if license != nil || !trialOver {
                    TopBarView(
                        panGestureCounter: panGestureCounter,
                        scale: actualScale,
                        panPadding: panPadding,
                        hide: hide
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
                            case .shelf: ShelfView(hovered: false, full: true)
                        }
                    }
                }
                .scaleEffect(actualScale, anchor: .top)
                .transition(NotchView.defaultTransition)
            }
        }
        .compositingGroup()
        .blur(radius: scaleDown * 100)
        .fixedSize(horizontal: true, vertical: false)
        .frame(
            minWidth: notchHeight == 0 ? generalSettings.handleSize.width : NotchShape.getNotchWidthForScreenWidth(screenSize.width),
            minHeight: notchHeight == 0 ? generalSettings.handleSize.height : notchHeight
        )
        .padding(mode == .closed ? panPadding : .zero)
        .padding(standardPadding)
        .coordinateSpace(name: "drop-zone")
        .mask(alignment: .top) { shapeView(shadow: false, transparentHandle: false) }
        .background {
            NotchGesturer(
                hidden: hide,
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
        .contentShape(NotchShape(notchHeight: notchHeight))
        .background {
            if mode == .closed || mode == .dragging {
                FileDropView(dropEntered: dropEntered, dropUpdated: dropUpdated, performDrop: performDrop, dropExited: dropExited)
            }
        }
        .background(alignment: .top) { shapeView() }
        .offset(x: (-panPadding.leading + panPadding.trailing) / 3)
        .animation(.smooth(extraBounce: 0.15), value: [liveActivitiesSettings])
        .animation(.smooth(extraBounce: 0.15), value: intro)
        .onTapGesture { if mode == .closed && !showIntro { openNotch() } }
        .onLongPressGesture(minimumDuration: 0.3, maximumDistance: 30, perform: {}, onPressingChanged: { pressing in
            if hovering {
                withAnimation(.bouncy(extraBounce: 0.15)) {
                    self.pressing = pressing
                }
            }
        })

        .onHover { hovering in
            if license == nil || trialOver { checkTrialOver() }
            
            if hovering {
                if mode == .closed {
                    if !isShelfEmpty || generalSettings.alwaysOpenNotchOnHover {
                        openNotch(in: isShelfEmpty ? .nook : .shelf)
                    } else {
                        withAnimation(.bouncy(duration: 0.4, extraBounce: 0.25)) {
                            self.hovering = true
                        }
                    }
                }
            } else {
                closeNotch(unhover: true)
            }
        }
        .contextMenu {
            Button("Open Settings") { openSettings(nil) }
            Button("Quit NotchNook") { NSApp.terminate(nil) }
        }
        .onAppear {
            let oldShorts = Defaults[.shortcutsWidgetSettings].shortcutsToDisplay
            let newShorts = oldShorts.filter { ShortcutsManager.shared.shortcuts.contains($0) }
            Defaults[.shortcutsWidgetSettings].shortcutsToDisplay = newShorts
        }
        .onChange(of: hovering) { if !$0 && $1 { vibrate() } }
        .onChange(of: hoveredDropTargetID) { oldValue, newValue in
            if oldValue != newValue && newValue != nil {
                vibrate()
            }
        }
        .onChange(of: intro, initial: true) { _, new in
            doThisAfter(0.3) {
                withAnimation(.bouncy(extraBounce: 0.15)) {
                    showIntro = new
                }
            }
        }
        .onChangeDebounced(of: panRawPadding, delay: 0.05) { _ in
            withAnimation(.smooth) { panRawPadding = .zero }
        }
        .onChangeDebounced(of: scaleDown, delay: 0.05) { _ in
            withAnimation(.smooth) { scaleDown = 0 }
        }
        .frame(width: screenSize.width, height: screenSize.height, alignment: .top)
        .fixedSize()
        .environment(\.namespace, ns)
        .environment(\.trialOver, trialOver)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Drag and drop files into shelf functons
    
    func finishDragging(close: Bool) {
        if droppingCoords != nil { droppingCoords = nil }
        
        withAnimation(.smooth(duration: 0.4)) {
            if !availableActions.isEmpty {
                availableActions.removeAll()
            }
            if mode != .closed {
                NotchNook.shared.mode[screenID] = close ? .closed : .shelf
            }
        }
    }
    
    func dropEntered(info: NSDraggingInfo) {
                if trialOver { return }
                withAnimation(.bouncy(extraBounce: 0.15)) {
                    NotchNook.shared.mode[screenID] = .dragging
                }
                DispatchQueue.main.async {
                    let actionsToShow = allDropActions.filter { action in
                        return info.draggingPasteboard.types?.contains(action.allowedFileTypes) ?? false
                    }
                    withAnimation(.bouncy(extraBounce: 0.15)) {
                        availableActions = actionsToShow
                    }
                }
    }
    
    func dropUpdated(info: NSDraggingInfo, mousePos: CGPoint) {
        if trialOver { return }
        droppingCoords = mousePos
    }

    func performDrop(info: NSDraggingInfo) -> Bool {
        if trialOver { return false }
        let isShelf = hoveredDropTargetID == ShelfView.id
        var cb: (([URL]) -> ()) = Shelf.shared.addFilesFromURLs
        let dropAction = allDropActions.first(where: { $0.id == hoveredDropTargetID })
        var hasFiles = false
        let loadItemGroup = DispatchGroup()
        
        if !isShelf, let dropAction {
            cb = { urls in
                dropAction.action(urls, .zero)
            }
        }
        
        let pasteboard = info.draggingPasteboard
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL], !fileURLs.isEmpty {
            hasFiles = true
            DispatchQueue.main.async {
                cb(fileURLs)
            }
        }
        
        guard let promiseReceivers = info.draggingPasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil) as? [NSFilePromiseReceiver] else {
            finishDragging(close: true)
            return false
        }
        
        let randomDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: randomDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        
        for receiver in promiseReceivers {
            hasFiles = true
            loadItemGroup.enter()
            receiver.receivePromisedFiles(atDestination: randomDirectoryURL, options: [:], operationQueue: OperationQueue()) { fileURL, error in
                defer { loadItemGroup.leave() }
                if let error = error {
                    print("Error receiving file: \(error)")
                } else {
                    DispatchQueue.main.async {
                        cb([fileURL])
                    }
                }
            }
        }

        loadItemGroup.notify(queue: .main) {
            finishDragging(close: !hasFiles && !isShelf)
        }

        return true
    }
    
    func dropExited(info: NSDraggingInfo) {
        finishDragging(close: Shelf.shared.files.count == 0)
    }
    
    // MARK: - Functions related to the View way of working
    
    func openNotch(in newMode: NotchNook.NotchMode = .nook) {
        hideTimer?.invalidate()
        withAnimation(Self.animation) {
            cancelPan = true
            if hide { hide = false } else {
                NotchNook.shared.mode[screenID] = newMode
            }
        } completion: {
            cancelPan = false
        }
    }
    
    func closeNotch(vibrate doVibrate: Bool = false, unhover: Bool = false) {
        withAnimation(.smooth(duration: 0.4)) {
            self.cancelPan = true
            if unhover {
                self.hovering = false
            }
            if doVibrate { vibrate() }
            if mode != .closed {
                NotchNook.shared.mode[screenID] = .closed
            }
        } completion: {
            cancelPan = false
        }
    }
    
    func changeTrack(prev: Bool) {
        withAnimation(.smooth) {
            vibrate()
            panRawPadding = .zero
            cancelPan = true
            if prev { panGestureCounter -= 1 } else { panGestureCounter += 1 }
        }
    }
    
    func hideNotch() {
        if hide { return }
        hideTimer?.invalidate()
        vibrate()
        withAnimation(.smooth) {
            hide = true
            hideTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
                withAnimation(.smooth) { hide = false }
            }
        }
    }
}
