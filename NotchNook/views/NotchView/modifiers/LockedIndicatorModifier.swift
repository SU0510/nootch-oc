//
//  LockedIndicatorModifier.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/06/24.
//

import SwiftUI

extension NotchView {
    struct LockedIndicatorModifier: ViewModifier {
        var state: NotchViewModel
        @Environment(\.notchNook) internal var notchNook
        @Environment(\.isEditingText) internal var isEditingText
        func body(content: Content) -> some View {
            content
                .overlay(alignment: .bottomTrailing) {
                    if notchNook.mode != .closed && notchNook.mode != .dragging {
                        LockedIndicatorView(
                            locked: notchNook.locked,
                            toggleLock: { notchNook.locked.toggle() },
                            typing: isEditingText
                        )
                        .scaleEffect(1 - state.scaleDown, anchor: .topLeading)
                        .blur(radius: state.scaleDown * 100)
                        .offset(x: 20, y: 20)
                        .transition(.scaleAndBlur(anchor: .topLeading))
                    }
                }
        }
    }
}

