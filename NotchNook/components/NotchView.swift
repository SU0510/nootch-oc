//
//  Notch.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct NotchView: View, DropDelegate {
    var defaultNotchHeight: CGFloat
    @State private var mode: NotchMode = .closed
    @State private var fileHovering: URL?
    @State private var droppingCoords: CGPoint?
    @State private var availableActions: [DropAction]?
    @State private var targetsCoords = [String:CGRect]()
    
    var hoveredDropTargetID: String? {
        if let droppingCoords,
           let found = targetsCoords.first(where: { $1.contains(droppingCoords) }) {
            return found.key
        }
        return nil
    }
    
    var body: some View {
        let isDragging = droppingCoords != nil
        let filesShelfCount = Shelf.shared.files.count
        let isShelfEmpty = filesShelfCount == 0
        let collapsedWidth: CGFloat = (mode == .closed || mode == .hovering || mode == .pressing) && !isShelfEmpty ? 80 : 0
        let actualShapeConfig = mode.notchShapeConfig
        let defaultTransition = AnyTransition.asymmetric(insertion: .scaleAndBlur(anchor: .top).animation(.smooth(duration: 0.35).delay(0.1)), removal: .scaleAndBlur(anchor: .top).animation(.smooth(duration: 0.2)))
        ZStack(alignment: .top) {
            
            HStack(spacing: 8) {
                if collapsedWidth != 0 {
                    Group {
                        Image(systemName: "shippingbox.fill")
                        Color.clear.frame(width: NotchShape.defaultNotchWidth)
                        HStack(spacing: 2) {
                            Text("\(filesShelfCount)")
                            Image(systemName: "doc.fill")
                        }
                    }
                    .transition(.scaleAndBlur)
                }
            }
            .frame(width: NotchShape.defaultNotchWidth + collapsedWidth, height: defaultNotchHeight)
            .zIndex(1)
            .allowsHitTesting(false)

            
            
            if mode == .open || mode == .dropping {
                HStack(spacing: 8) {
                    
                    Group {
                        
                        if !isShelfEmpty || availableActions != nil {
                            ShelfView(hovered: hoveredDropTargetID == ShelfView.id, full: !isShelfEmpty && mode == .dropping)
                                .bindDropAreaCoords(
                                    coordinatedSpace: .named("drop-zone"),
                                    Binding(
                                        get: { targetsCoords[ShelfView.id] ?? .zero },
                                        set: { val in targetsCoords[ShelfView.id] = val }
                                    )
                                )
                                .zIndex(1)
                        }
                        
                        if let availableActions {
                            ForEach(availableActions) { action in
                                DropActionView(action: action, hovered: hoveredDropTargetID == action.id)
                                    .bindDropAreaCoords(
                                        coordinatedSpace: .named("drop-zone"),
                                        Binding(
                                            get: { targetsCoords[action.id] ?? .zero },
                                            set: { val in targetsCoords[action.id] = val }
                                        )
                                    )
                            }
                        }
                        
                    }
                    .transition(defaultTransition)
                    
                }
                .padding(.top, defaultNotchHeight)
                .padding(.all, (!isShelfEmpty && (mode == .open || (mode == .dropping && availableActions == nil))) ? 8 : 12)
                .frame(width: NotchMode.dropping.notchShapeConfig.width, height: defaultNotchHeight + NotchMode.dropping.notchShapeConfig.height)
                .coordinateSpace(name: "drop-zone")
                .zIndex(1)
                .allowsHitTesting(!isDragging)
                .transition(defaultTransition)
            }
            
        }
//        .frame(width: NotchShape.defaultNotchWidth + actualShapeConfig.width, height: height + actualShapeConfig.height, alignment: .top)
        .frame(minWidth: NotchShape.defaultNotchWidth, minHeight: defaultNotchHeight)
        .clipShape(NotchShape(minHeight: defaultNotchHeight))
        .background {
            ShadowedNotchShapeView(minHeight: defaultNotchHeight)
        }
        .contentShape(NotchShape(minHeight: defaultNotchHeight))
        .onTapGesture {
            withAnimation(.bouncy(extraBounce: 0.075)) {
                self.mode = .open
            }
        }
        .onLongPressGesture(minimumDuration: 0.3, maximumDistance: 30, perform: {}, onPressingChanged: { pressing in
            if mode == .hovering || mode == .pressing {
                withAnimation(.bouncy(extraBounce: 0.15)) {
                    mode = pressing ? .pressing : .closed
                }
            }
        })
        .onDrop(of: [.fileURL], delegate: self)
        .onHover { hovering in
            if hovering {
                if mode == .closed {
                    if !isShelfEmpty {
                        withAnimation(.bouncy(extraBounce: 0.075)) {
                            self.mode = .open
                        }
                    } else {
                        withAnimation(.bouncy(duration: 0.4, extraBounce: 0.25)) {
                            self.mode = .hovering
                        }
                    }
                }
            } else {
                if mode != .closed {
                    withAnimation(.smooth(duration: 0.4)) { self.mode = .closed }
                }
            }
        }
        .onChange(of: mode) { oldValue, newValue in
            if oldValue != newValue && (newValue == .hovering || newValue == .dropping) {
                NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
            }
        }
        .onChange(of: hoveredDropTargetID) { oldValue, newValue in
            if oldValue != newValue && newValue != nil {
                NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
            }
        }
        .frame(width: 1000, height: 300, alignment: .top)
        .fixedSize()
    }
    
    func finishDragging(close: Bool) {
        if droppingCoords != nil { droppingCoords = nil }
        
        if availableActions != nil || (close && mode != .closed) {
            withAnimation(.smooth(duration: 0.4)) {
                availableActions = nil
                if close { mode = .closed }
            }
        }
    }
    
    func dropEntered(info: DropInfo) {
        // Assuming info has a property of `fileTypes` that lists all types of the files
        //        let fileTypeSet = Set(info.fileTypes)
        withAnimation(.bouncy(extraBounce: 0.15)) {
            mode = .dropping
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
            finishDragging(close: Shelf.shared.files.count == 0 && !isShelf)
            cb($0)
        })
        return true
    }
    
    func dropExited(info: DropInfo) {
        finishDragging(close: Shelf.shared.files.count == 0)
    }
    
    enum NotchMode {
        case hovering, dropping, open, closed, pressing
        
        var notchShapeConfig: NotchShapeConfig {
            return switch self {
            case .closed: .init(height: 0, width: 0, decorationsRadius: 5, notchRadius: 11, shadow: false)
            case .hovering: .init(height: 10, width: 20, decorationsRadius: 22, notchRadius: 14, shadow: true)
            case .pressing: .init(height: 7, width: 14, decorationsRadius: 19, notchRadius: 11, shadow: true)
            case .dropping: .init(height: 100, width: 300, decorationsRadius: 40, notchRadius: 24, shadow: true)
            case .open: .init(height: 100, width: 300, decorationsRadius: 40, notchRadius: 24, shadow: true)
            }
        }
    }
}



