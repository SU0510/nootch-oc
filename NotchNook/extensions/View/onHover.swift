//
//  onHover.swift
//  NotchNook
//
//  Created by Igor Marcossi on 31/08/24.
//

import SwiftUI

struct OnHoverModifier<Output: View, Input: View>: ViewModifier {
    var animation: Animation? = nil
    @ViewBuilder var transformedView: (Input, Bool) -> Output
    @State private var hovering = false
    func body(content: Content) -> some View {
        transformedView(content as! Input, hovering)
            .onHover { newHovering in
                withAnimation(animation) {
                    self.hovering = newHovering
                }
            }
    }
}

extension View {
    @ViewBuilder func onHover<Output: View>(@ViewBuilder _ transformedView: @escaping (Self, Bool) -> Output) -> some View {
        self
            .modifier(OnHoverModifier(transformedView: transformedView))
    }
}
