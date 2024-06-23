//
//  TopBarSpacerView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/05/24.
//

import SwiftUI
import Defaults

struct TopBarSpacerView: View {
    @Environment(\.screenSize) private var screenSize
    @Environment(\.notchHeight) private var notchHeight
    @Default(.generalSettings) private var generalSettings
    var height: Double
    var body: some View {
        Color.clear
            .frame(width: screenSize.width == 0 ? NotchShape.defaultNotchWidth : notchHeight == 0 ? generalSettings.handleSize.width : NotchShape.getNotchWidthForScreenWidth(screenSize.width), height: height)
            .transition(.identity)
    }
}
