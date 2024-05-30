//
//  CircleButton.swift
//  NotchNook
//
//  Created by Igor Marcossi on 22/05/24.
//

import SwiftUI

struct CircleButton: View {
    var icon: String
    var iconSize: Double = 10
    var fade: Bool = true
    var bgColor: Color = .selected
    var action: () -> ()
    @State private var hovering = false
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .contentTransition(.symbolEffect)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.white.opacity(fade && !hovering ? 0.75 : 1))
                .frame(27)
                .background(bgColor.opacity(hovering ? 1 : 0), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(ShrinkOnClick())
        .onHover { newHovering in
            withAnimation(.easeOut(duration: 0.2)) { hovering = newHovering }
        }
    }
}
