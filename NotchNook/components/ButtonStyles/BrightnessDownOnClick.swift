//
//  BrightnessDownOnClick.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI

struct BrightnessDownOnClick: ButtonStyle {
    var cornerRadius: Double = 0
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.black.opacity(configuration.isPressed ? 0.05 : 0))
                    .blendMode(.plusDarker)
            }
    }
}
