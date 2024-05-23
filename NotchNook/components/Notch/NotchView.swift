//
//  Notch.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct NotchView: View, DropDelegate {
    static let maxPanDrag: Double = 16
    static let panVelocityTriggerThreshold: Double = 500
    static let defaultTransition = AnyTransition.asymmetric(insertion: .scaleAndBlur(anchor: .top).animation(.smooth(duration: 0.35).delay(0.1)), removal: .scaleAndBlur(anchor: .top).animation(.smooth(duration: 0.2)))
    
    var defaultNotchHeight: CGFloat
    @State private var droppingCoords: CGPoint?
    @State private var pressing = false
    @State private var hovering = false
    @State private var cancelPan = false
    @State private var availableActions = [DropAction]()
    @State private var targetsCoords = [String:CGRect]()
    @State private var panRawPadding: EdgeInsets = .zero
    @State private var scaleDown: Double = 0
//    @State private var pan: CGSize = .zero
    @Namespace private var ns
    
    var hoveredDropTargetID: String? {
        if let droppingCoords,
           let found = targetsCoords.first(where: { $1.contains(droppingCoords) }) {
            return found.key
        }
        return nil
    }
    
    var panPadding: EdgeInsets {
        let leadingInterpolator = interpolatorBuilder([0, 150], value: panRawPadding.leading)
        let trailingInterpolator = interpolatorBuilder([0, 150], value: panRawPadding.trailing)
        let bottomInterpolator = interpolatorBuilder([0, 200], value: panRawPadding.bottom)

        let max: Double = 16
        
        let leading = leadingInterpolator([0, max], true)
        let trailing = trailingInterpolator([0, max], true)
        let bottom = bottomInterpolator([0, max], true)
        
        return .init(
            top: 0,
            leading: (bottom * 0.5) + leading,
            bottom: (((leading + trailing) / 2) * 0.25) + bottom,
            trailing: (bottom * 0.5) + trailing
        )
    }
    
    func vibrate() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }
    
    func openNotch(in newMode: NotchNook.NotchMode = .nook) {
        withAnimation(.bouncy(extraBounce: 0.075)) {
            cancelPan = true
            NotchNook.shared.mode = newMode
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
            if NotchNook.shared.mode != .closed {
                NotchNook.shared.mode = .closed
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
            if prev {
                MediaPlayer.shared.previousTrack()
            } else {
                MediaPlayer.shared.nextTrack()
            }
        } completion: {
            cancelPan = false
        }
    }
    
    @ViewBuilder func shapeView(shadow: Bool? = nil) -> some View {
        GeometryReader { geo in
            ShadowedNotchShapeView(minHeight: defaultNotchHeight, shadow: shadow ?? (NotchNook.shared.mode != .closed || hovering))
                .frame(width: geo.size.width * (1 - scaleDown), height: geo.size.height * (1 - scaleDown), alignment: .top)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }
    
    var body: some View {
        let mode = NotchNook.shared.mode
        let filesShelfCount = Shelf.shared.files.count
        let isShelfEmpty = filesShelfCount == 0
        
        VStack(alignment: .center, spacing: 8) {
            TopBarView(defaultNotchHeight: defaultNotchHeight, scaleDown: 1 - scaleDown, panPadding: panPadding, ns: ns)
//                .scaleEffect(1)

            Group {
                switch mode {
                case .closed: EmptyView()
                case .dragging: DropActionsView(targetsCoords: $targetsCoords, availableActions: availableActions, hoveredDropTargetID: hoveredDropTargetID)
                case .nook: NookView(ns: ns)
                case .shelf: ShelfView(hovered: false, full: true)
                }
            }
            .scaleEffect(1 - scaleDown, anchor: .top)
            .transition(NotchView.defaultTransition)
            
        }
        .compositingGroup()
        .blur(radius: scaleDown * 100)
        .padding(mode == .closed ? panPadding : .zero)
        .padding([.leading, .bottom, .trailing], mode == .closed ? hovering ? pressing ? 4 : 8 : 0 : 12)
        .coordinateSpace(name: "drop-zone")
        .fixedSize(horizontal: true, vertical: false)
        .frame(minWidth: NotchShape.defaultNotchWidth, minHeight: defaultNotchHeight)
        .mask(alignment: .top) { shapeView(shadow: false) }
        .background {
            ScrollWheelViewRepresentable { translation, scrollingPoint, velocity, cancelGesture in
                if cancelPan { return }
                
                if mode != .closed {
                    if scrollingPoint.y < 0 {
                        let interpolate = interpolatorBuilder([0, -150], value: scrollingPoint.y)
                        
                        scaleDown += interpolate([0, 0.1], true)
                        
                        if scaleDown > 0.03 || velocity.height < -NotchView.panVelocityTriggerThreshold {
                            closeNotch(vibrate: true)
                        }
                    }
                    return
                }
                
                panRawPadding = .init(
                    top: 0,
                    leading: panRawPadding.leading + (scrollingPoint.x < 0 ? abs(scrollingPoint.x) : 0),
                    bottom: panRawPadding.bottom + (scrollingPoint.y > 0 ? scrollingPoint.y : 0),
                    trailing: panRawPadding.trailing + (scrollingPoint.x > 0 ? scrollingPoint.x : 0)
                )
                
                if scrollingPoint.x > 0 {
                    withAnimation(.smooth) { panRawPadding.leading = 0 }
                } else if scrollingPoint.x < 0 {
                    withAnimation(.smooth) { panRawPadding.trailing = 0 }
                }
                                
                if velocity.height > NotchView.panVelocityTriggerThreshold {
                    openNotch()
                }
                
                if velocity.width < -NotchView.panVelocityTriggerThreshold {
                    changeTrack(prev: true)
                }
                if velocity.width > NotchView.panVelocityTriggerThreshold {
                    changeTrack(prev: false)
                }
                
            } onDragEnded: { translation, scrollingPoint, velocity in
                cancelPan = false
            }
            .id(mode.rawValue + cancelPan.description)
        }
        .background(alignment: .top) { shapeView() }
        .contentShape(NotchShape(minHeight: defaultNotchHeight))
        .offset(x: (-panPadding.leading + panPadding.trailing) / 3)
        .onTapGesture { if mode == .closed { openNotch() } }
        .onLongPressGesture(minimumDuration: 0.3, maximumDistance: 30, perform: {}, onPressingChanged: { pressing in
            if hovering {
                withAnimation(.bouncy(extraBounce: 0.15)) {
                    self.pressing = pressing
                }
            }
        })
        .onDrop(of: [.fileURL], delegate: self)
        .onHover { hovering in
            if hovering {
                if mode == .closed {
                    if !isShelfEmpty {
                        openNotch(in: .shelf)
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
        .onChange(of: panPadding) { _, newPanPaddig in
            if newPanPaddig.bottom > NotchView.maxPanDrag && mode == .closed {
                openNotch()
            }
            if newPanPaddig.bottom < NotchView.maxPanDrag / 3 {
                if newPanPaddig.leading > NotchView.maxPanDrag {
                    changeTrack(prev: true)
                }
                if newPanPaddig.trailing > NotchView.maxPanDrag {
                    changeTrack(prev: false)
                }
            }
        }
        .onChange(of: hovering) { if !$0 && $1 { vibrate() } }
        .onChange(of: mode) { oldValue, newValue in
            if oldValue != newValue && newValue != .closed { vibrate() }
        }
        .onChange(of: hoveredDropTargetID) { oldValue, newValue in
            if oldValue != newValue && newValue != nil {
                vibrate()
            }
        }
        .onChangeDebounced(of: panRawPadding, delay: 0.05) { _ in
            withAnimation(.smooth) { panRawPadding = .zero }
        }
        .onChangeDebounced(of: scaleDown, delay: 0.05) { _ in
            withAnimation(.smooth) { scaleDown = 0 }
        }
        .frame(width: 1000, height: 300, alignment: .top)
        .fixedSize()
    }
    
    func finishDragging(close: Bool) {
        if droppingCoords != nil { droppingCoords = nil }
        
        if !availableActions.isEmpty || (close && NotchNook.shared.mode != .closed) {
            withAnimation(.smooth(duration: 0.4)) {
                availableActions.removeAll()
                NotchNook.shared.mode = close ? .closed : .shelf
            }
        }
    }
    
    func dropEntered(info: DropInfo) {
        withAnimation(.bouncy(extraBounce: 0.15)) {
            NotchNook.shared.mode = .dragging
        }
        DispatchQueue.main.async {
            let actionsToShow = allDropActions.filter { action in
                action.allowedFileTypes.allSatisfy { fileType in
                    info.hasItemsConforming(to: [fileType])
                }
            }
            withAnimation(.bouncy(extraBounce: 0.15)) {
                availableActions = actionsToShow
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        droppingCoords = info.location
        return nil
    }
    
    func performDrop(info: DropInfo) -> Bool {
        
        let isShelf = hoveredDropTargetID == ShelfView.id
        var allowedTypes: [UTType] = isShelf ? [.fileURL] : []
        var cb: (([URL]) -> ()) = Shelf.shared.addFilesFromURLs
        
        let dropAction = allDropActions.first(where: { $0.id == hoveredDropTargetID })
        
        if !isShelf, let dropAction {
            allowedTypes = dropAction.allowedFileTypes
            cb = { urls in
                dropAction.action(urls, .zero)
            }
        }
        
        if !isShelf && dropAction == nil { return false }
        
        getURLsFromDropInfo(info, allowedTypes: allowedTypes, cb: {
            cb($0)
            finishDragging(close: Shelf.shared.files.count == 0 && !isShelf)
        })
        return true
    }
    
    func dropExited(info: DropInfo) {
        finishDragging(close: Shelf.shared.files.count == 0)
    }
}



