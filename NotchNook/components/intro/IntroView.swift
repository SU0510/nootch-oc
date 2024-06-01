//
//  IntroView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI
import Lottie
import Defaults

struct IntroView: View {
    @State private var tutorial = false
    @Environment(\.notchHeight) private var notchHeight
    @Default(.intro) private var intro
    @Default(.trialInitialTime) private var trialInitialTime
    @Default(.license) private var license
    var body: some View {
        ZStack {
            Group {
                if tutorial {
                    TutorialView()
                } else {
                    HelloView(tutorial: $tutorial)
                }
            }
        }
        .padding(.top, notchHeight)
        .foregroundStyle(.white)
    }
}
