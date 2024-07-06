//
//  MediaWidgetSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/05/24.
//

import SwiftUI
import Settings

struct MediaWidgetSettingsView: View {
    var body: some View {
        Settings.Container(contentWidth: 520.0) {
            Settings.Section(title: String(localized: "")) {
                BlankView(message: "No options for this one")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
