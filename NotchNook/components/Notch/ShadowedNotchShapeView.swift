//
//  NotchShapeView.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI

struct ShadowedNotchShapeView: View {
    var shadow: Bool
    @Environment(\.notchHeight) private var notchHeight
    var body: some View {
        NotchShape(notchHeight: notchHeight)
            .fill(.black.shadow(.drop(
                color: .black.opacity(shadow ? 0.75 : 0),
                radius: shadow ? 20 : 0,
                x: 0,
                y: shadow ? 8 : 0
            )))
    }
}
