//
//  BlinkingLogoView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI

struct BlinkingLogoView: View {
    @State private var letterOActive = true
    @State private var letterFEActive = true
    @State private var lettersActive = true
    @State private var decreasedDelay = 0

    var body: some View {
        VStack {
            ZStack {
                if !lettersActive {
                    Image(.loCafeLogoFullOff).resizable()
                } else if letterOActive {
                    if letterFEActive {
                        Image(.loCafeLogoFullOn).resizable()
                    } else {
                        Image(.loCafeLogoFeOff).resizable()
                    }
                } else {
                    if letterFEActive {
                        Image(.loCafeLogoOOff).resizable()
                    } else {
                        Image(.loCafeLogoOFeOff).resizable()
                    }
                }
            }
            .scaledToFill()
            .frame(width: 529, height: 337)
        }
        .frame(width: 356, height: 84)
        .onAppear {
            setRandomizeTimeout()
        }
    }

    private func randomize() {
        let letterORandom = Double.random(in: 0...1) > 0.175
        let letterFERandom = Double.random(in: 0...1) > 0.1
        let fullActiveRandom = Double.random(in: 0...1) > 0.05

        if letterORandom == letterOActive && letterFERandom == letterFEActive && fullActiveRandom == lettersActive {
            decreasedDelay += 1
        } else {
            decreasedDelay = 0
            letterOActive = letterORandom
            letterFEActive = letterFERandom
            lettersActive = fullActiveRandom
        }

        setRandomizeTimeout()
    }

    private func setRandomizeTimeout() {
        let allOn = letterOActive && letterFEActive && lettersActive
        let nextRunActualRandomMs = Double.random(in: 0...1) > 0.5 ?
            Double.random(in: 0...1) * Double(max(0, (allOn ? 1250 : lettersActive ? 750 : 500) - decreasedDelay * 150)) :
            Double.random(in: 0...1) * 200

        DispatchQueue.main.asyncAfter(deadline: .now() + nextRunActualRandomMs / 1000) {
            self.randomize()
        }
    }
}
