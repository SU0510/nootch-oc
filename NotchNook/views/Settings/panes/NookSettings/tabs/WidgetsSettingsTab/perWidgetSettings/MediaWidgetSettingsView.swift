//
//  MediaWidgetSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/05/24.
//

import SwiftUI

struct MediaWidgetSettingsView: View {
    var body: some View {
        Form {
            BlankView(message: "No options for this one")
                .frame(maxWidth: .infinity)
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}
