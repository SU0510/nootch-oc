//
//  NotchSpacerView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/05/24.
//

import SwiftUI

struct NotchSpacerView: View {
    @Environment(\.notchHeight) private var notchHeight
    var body: some View {
        Color.clear
            .frame(width: NotchShape.defaultNotchWidth, height: notchHeight).fixedSize(horizontal: true, vertical: true)
            .transition(.identity)
    }
}
