//
//  LicenseSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/05/24.
//

import SwiftUI
import Settings

struct LicenseSettingsView: View {
    var body: some View {
        Settings.Container(contentWidth: 450.0) {
            Settings.Section(title: "Section Title") {
                Text("Tudo bem?")
            }
//            Settings.Section(label: {
//                // Custom label aligned on the right side.
//            }) {
//                // Some view.
//            }
        }
        .transition(.identity)
    }
}

#Preview {
    LicenseSettingsView()
}
