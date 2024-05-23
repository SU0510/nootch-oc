//
//  DropActionsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI

struct DropActionsView: View {
    @Binding var targetsCoords: [String:CGRect]
    var availableActions: [DropAction]
    var hoveredDropTargetID: String?

    var body: some View {
        HStack(spacing: 8) {
            
            Group {
                
                    ShelfView(hovered: hoveredDropTargetID == ShelfView.id, full: false)
                        .bindDropAreaCoords(
                            coordinatedSpace: .named("drop-zone"),
                            Binding(
                                get: { targetsCoords[ShelfView.id] ?? .zero },
                                set: { val in targetsCoords[ShelfView.id] = val }
                            )
                        )
                        .zIndex(1)
                
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
            .transition(NotchView.defaultTransition)
            
        }
//        .padding(.top, defaultNotchHeight)
//        .padding(.all, (!isShelfEmpty && (mode == .open || (mode == .dropping && availableActions == nil))) ? 8 : 12)
        .defaultOpenSize()
        .zIndex(1)
        .allowsHitTesting(false)
        .transition(NotchView.defaultTransition)
    }
}
