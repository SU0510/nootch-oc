//
//  StartButton.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI
import Defaults

struct StartButton: View {
    @Default(.intro) private var intro
    @Default(.license) private var license
    @Default(.trialInitialTime) private var trialInitialTime
    var body: some View {
        if license != nil {
            Button("Start") { intro = false }
        } else {
            Button("Start \(Int(LicenseManager.trialDurationInHours))h Trial", systemImage: "clock") {
                intro = false
                if trialInitialTime == nil {
                    trialInitialTime = Date().timeIntervalSince1970
                }
            }
        }
    }
}

#Preview {
    StartButton()
}
