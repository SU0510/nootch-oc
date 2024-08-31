//
//  ActionButton.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI

struct ActionButton: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .background(.blue, in: Capsule(style: .continuous))
            .brightness(configuration.isPressed ? -0.1 : 0)
            .foregroundStyle(.nonShockingWhite)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.smooth(duration: 0.35, extraBounce: 0.5), value: configuration.isPressed)
    }
}
