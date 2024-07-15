//
//  syncOriginWithExpandedNoteManger.swift
//  NotchNook
//
//  Created by Igor Marcossi on 14/07/24.
//

import SwiftUI

struct SyncOriginWithExpandedNoteMangerModifier: ViewModifier {
    var id: String
    @Environment(\.expandedNoteManager) private var expandedNoteManager
    @Environment(\.screenSize) private var screenSize
    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onChange(of: geo.frame(in: .global), initial: true) { oldValue, newValue in
                            let origin = CGPoint(x: newValue.midX, y: (screenSize.height - NotchView.windowHeight) + newValue.midY)
                            expandedNoteManager.setButtonOrigin(of: id, to: origin)
                        }
                }
            }
    }
}

extension View {
    func syncOriginWithExpandedNoteManger(id: String) -> some View {
        self
            .modifier(SyncOriginWithExpandedNoteMangerModifier(id: id))
    }
}
