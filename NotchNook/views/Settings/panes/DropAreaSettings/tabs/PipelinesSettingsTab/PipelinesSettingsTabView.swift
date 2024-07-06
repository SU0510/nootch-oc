//
//  PipelinesSettingsTabView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI
import Settings

struct PipelinesSettingsTabView: View {
    var body: some View {
        Settings.Container(contentWidth: 520.0) {
            Settings.Section(title: String(localized: "")) {
                Text("Soon you'll be able to compress images, zip/unzip files and much more by dragging and dropping files.")
                    .padding(.top, 32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(0.5)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
