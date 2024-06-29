//
//  optionDescription.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/06/24.
//

import SwiftUI
import Settings

extension View {
    func optionDescription(_ maxWidth: Double) -> some View {
        self
            .fixedSize(horizontal: false, vertical: true)
            .settingDescription()
            .frame(width: maxWidth, alignment: .leading)
    }
}
