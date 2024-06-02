//
//  TopBarSpacerView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/05/24.
//

import SwiftUI

struct TopBarSpacerView: View {
    @Environment(\.screenSize) private var screenSize
    var height: Double
    var body: some View {
        Color.clear
            .frame(width: NotchShape.getNotchWidthForScreenWidth(screenSize.width), height: height).fixedSize(horizontal: true, vertical: true)
            .transition(.identity)
    }
}
