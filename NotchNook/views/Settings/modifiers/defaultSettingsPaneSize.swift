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
            .frame(width: 610, height: height, alignment: .topLeading)
            .fixedSize()
            .onAppear {
                DispatchQueue.main.async {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                }
            }
    }
}
