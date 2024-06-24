//
//  TopBarSpacerView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/05/24.
//

import SwiftUI
import Defaults

struct TopBarSpacerView: View {
    @Environment(\.notchSize) private var notchSize
    @Default(.generalSettings) private var generalSettings
    var height: Double
    var body: some View {
        Color.clear
            .frame(width: notchSize.width == 0 ? generalSettings.handleSize.width : notchSize.width, height: height)
            .frame(notchSize)
            .transition(.identity)
    }
}
