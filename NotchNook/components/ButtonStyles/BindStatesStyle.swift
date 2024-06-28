//
//  BindStatesStyle.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/06/24.
//

import SwiftUI

struct BindStatesStyle: ButtonStyle {
    @Binding var pressing: Bool
    @Binding var hovering: Bool
    
    init(
        pressing: Binding<Bool>? = nil,
        hovering: Binding<Bool>? = nil
    ) {
        let blankBinding = Binding(get: { false }, set: { _ in })
        self._pressing = pressing ?? blankBinding
        self._hovering = hovering ?? blankBinding
    }
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { pressing = $1 }
            .onHover { hovering = $0 }
    }
}
