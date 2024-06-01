//
//  TrialOverView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 31/05/24.
//

import SwiftUI
import Defaults

struct LicenseStateView: View {
    @Default(.license) private var license
    @Default(.nookSettings) private var nookSettings
    @Default(.trialInitialTime) private var trialInitialTime
    @Environment(\.openSettings) private var openSettings
    @Environment(\.trialOver) private var trialOver
    @Environment(\.notchHeight) private var notchHeight
    var body: some View {
        VStack {
            if license == nil {
                if trialOver {
                    Text("I'm sorry, your trial is over.")
                } else {
                    Text("Sorry, you need to register to use NotchNook.")
                }
                HStack {
                    Button("Open Settings") { openSettings(.license) }
                    if !trialOver {
                        Button("Start Trial") { withAnimation(.smooth(extraBounce: 0.25)) { trialInitialTime = Date().timeIntervalSince1970 } }
                    }
                }
            } else {
                Text("Something is wrong.")
                Text("You shouldn't be seeing this.")
                Text("Send an email to hi@lo.cafe if this doesn't go away.")
            }
        }
        .frame(nookSettings.size.screenPtsCGSize)
        .padding(.top, 16)
        .padding(.top, notchHeight)
        .multilineTextAlignment(.center)
    }
}
