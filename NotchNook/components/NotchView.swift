//
//  Notch.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI
import UniformTypeIdentifiers

let NOTCH_WIDTH: CGFloat = 184
let NOTCHWAY_WIDTH: CGFloat = 1000

struct NotchView: View, DropDelegate {
    var height: CGFloat
    @State private var mode: NotchMode = .closed
    @State private var filesShelf = [URL]()
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
        let collapsedWidth: CGFloat = (mode == .closed || mode == .hovering || mode == .pressing) && filesShelf.count > 0 ? 80 : 0
        let actualShapeConfig = mode.notchShapeConfig
        let defaultTransition = AnyTransition.asymmetric(insertion: .scaleAndBlur(anchor: .top).animation(.smooth(duration: 0.35).delay(0.1)), removal: .scaleAndBlur(anchor: .top).animation(.smooth(duration: 0.2)))
        ZStack(alignment: .top) {
            
            HStack(spacing: 8) {
                if collapsedWidth != 0 {
                    Group {
                        Image(systemName: "shippingbox.fill")
                        Color.clear.frame(width: NOTCH_WIDTH)
                        HStack(spacing: 2) {
                            Text("\(filesShelf.count)")
                            Image(systemName: "doc.fill")
                        }
                    }
                    .transition(.scaleAndBlur)
                }
            }
            .frame(width: NOTCH_WIDTH + collapsedWidth, height: height)
            .zIndex(1)
            .allowsHitTesting(false)

            
            
            if mode == .open || mode == .dropping {
                HStack(spacing: 8) {
                    
                    Group {
                        
                        if filesShelf.count > 0 || availableActions != nil {
                            ShelfView(hovered: hoveredDropTargetID == ShelfView.id, filesURLs: filesShelf, full: filesShelf.count > 0 && mode == .dropping)
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
                .padding(.top, height)
                .padding(.all, (filesShelf.count > 0 && (mode == .open || (mode == .dropping && availableActions == nil))) ? 8 : 12)
                .frame(width: NotchMode.dropping.notchShapeConfig.width, height: height + NotchMode.dropping.notchShapeConfig.height)
                .coordinateSpace(name: "drop-zone")
                .zIndex(1)
                .allowsHitTesting(false)
                .transition(defaultTransition)
            }
            
        }
        .frame(width: actualShapeConfig.width + collapsedWidth, height: height + actualShapeConfig.height, alignment: .top)
        .clipShape(notchShape(extraWidth: collapsedWidth, baseHeight: height, config: actualShapeConfig))
        .background {
            NotchShapeView(extraWidth: collapsedWidth, baseHeight: height, config: actualShapeConfig)
        }
        .contentShape(notchShape(extraWidth: collapsedWidth, baseHeight: height, config: actualShapeConfig))
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
                    if filesShelf.count > 0 {
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
    
    func performDrop(info: DropInfo) -> Bool {
        
        let isShelf = hoveredDropTargetID == ShelfView.id
        var allowedTypes: [UTType] = isShelf ? [.fileURL] : []
        var cb: (([URL]) -> ()) = { urls in
            withAnimation(.smooth) {
                filesShelf = filesShelf + urls
            }
        }
        
        let dropAction = allDropActions.first(where: { $0.id == hoveredDropTargetID })
        
        if !isShelf, let dropAction {
            allowedTypes = dropAction.allowedFileTypes
            cb = { urls in
                dropAction.action(urls, .zero)
            }
        }
        
        if !isShelf && dropAction == nil { return false }
        
        getURLsFromDropInfo(info, allowedTypes: allowedTypes, cb: {
            availableActions = nil
            cb($0)
        })
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Assuming info has a property of `fileTypes` that lists all types of the files
        //        let fileTypeSet = Set(info.fileTypes)
        withAnimation(.bouncy(extraBounce: 0.15)) {
            mode = .dropping
        }
        DispatchQueue.main.async {
            var actionsToShow = allDropActions.filter { action in
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
    
    func dropExited(info: DropInfo) {
        withAnimation(.smooth(duration: 0.4)) {
            availableActions = nil
            droppingCoords = nil
            if filesShelf.count == 0 {
                mode = .closed
            }
        }
    }
    
    enum NotchMode {
        case hovering, dropping, open, closed, pressing
        
        var notchShapeConfig: NotchShapeConfig {
            return switch self {
            case .closed: .init(height: 0, width: NOTCH_WIDTH, outerRadius: 11, innerRadius: 5, shadow: false)
            case .hovering: .init(height: 10, width: NOTCH_WIDTH + 20, outerRadius: 22, innerRadius: 14, shadow: true)
            case .pressing: .init(height: 7, width: NOTCH_WIDTH + 14, outerRadius: 19, innerRadius: 11, shadow: true)
            case .dropping: .init(height: 100, width: NOTCH_WIDTH + 300, outerRadius: 40, innerRadius: 24, shadow: true)
            case .open: .init(height: 100, width: NOTCH_WIDTH + 300, outerRadius: 40, innerRadius: 24, shadow: true)
            }
        }
    }
}



