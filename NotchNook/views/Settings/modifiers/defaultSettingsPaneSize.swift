//
//  defaultSettingsPaneSize.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/05/24.
//

import SwiftUI

    extension View {
        func defaultSettingsProps(height: CGFloat? = nil) -> some View {
            self
                .frame(width: 600, height: height)
//                .frame(width: 600, height: 625)
                .fixedSize()
                .onAppear {
                     DispatchQueue.main.async {
                          NSApp.keyWindow?.makeFirstResponder(nil)
                     }
                 }
        }
    }
