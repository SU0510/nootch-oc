//
//  ShelfLiveActivitySettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

struct ShelfLiveActivitySettingsView: View {
    var body: some View {
        Form {
            BlankView(message: "No options for this one")
                .frame(maxWidth: .infinity)
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}
