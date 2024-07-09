//
//  DropArea.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI
import Defaults

struct DropArea: View {
    @Binding var targetsCoords: [String:CGRect]
    var availableActions: [DropAction]
    var hoveredDropTargetID: String?
    
    @Environment(\.dropAreaSettings) private var dropAreaSettings

    var body: some View {
        HStack(spacing: 8) {
            
            Group {
                
                DropAreaTrayTargetView(hovered: hoveredDropTargetID == TrayView.id)
                        .bindDropAreaCoords(
                            coordinatedSpace: .named("drop-zone"),
                            Binding(
                                get: { targetsCoords[TrayView.id] ?? .zero },
                                set: { val in targetsCoords[TrayView.id] = val }
                            )
                        )
                        .zIndex(1)
                
                    ForEach(availableActions) { action in
                        DropAreaTargetView(action: action, hovered: hoveredDropTargetID == action.id)
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
        .frame(dropAreaSettings.size.screenPtsCGSize)
        .zIndex(1)
        .allowsHitTesting(false)
        .transition(NotchView.defaultTransition)
    }
}
