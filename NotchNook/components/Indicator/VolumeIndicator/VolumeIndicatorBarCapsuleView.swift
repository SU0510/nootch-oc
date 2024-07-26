//
//  VolumeIndicatorBarCapsuleView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/07/24.
//

import SwiftUI
import DynamicColor

struct VolumeIndicatorBarCapsuleView: View {
    var color: Color
    var active: Bool
    var body: some View {
        let nsColor = NSColor(color)
        let whiteGradient = LinearGradient(colors: [.white, .white.opacity(0.1)], startPoint: .top, endPoint: .bottom)
        Capsule()
            .fill(
                color
                    .shadow(.drop(color: Color(nsColor: nsColor.lighter()).opacity(!active ? 0 : 1), radius: 4, x: 0, y: 0))
                    .shadow(.drop(color: Color(nsColor: nsColor.lighter()).opacity(!active ? 0 : 1), radius: 16, x: 0, y: 0))
                    .shadow(.drop(color: Color(nsColor: nsColor.lighter()).opacity(!active ? 0 : 1), radius: 24, x: 0, y: 0))
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(whiteGradient.opacity(!active ? 0 : 1), lineWidth: 0.22)
                    .blendMode(.overlay)
                    .padding(0.22)
            }
            .overlay {
                Capsule(style: .continuous)
                    .fill(whiteGradient)
                    .blendMode(.overlay).opacity(!active ? 0 : 0.6)
            }
    }
}
