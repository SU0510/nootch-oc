//
//  TutorialView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI
import Lottie

struct TutorialView: View {
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 24) {
                TutorialItemView(animation: "drag", description: "Swipe horizontally to change song tracks.")
                TutorialItemView(animation: "drag", description: "Swipe vertically to open, close or hide the notch.", rotate: -90)
                TutorialItemView(animation: "click", description: "Click to open the Nook, where your widgets live.")
            }
            
            StartButton()
                .buttonStyle(ActionButton())
        }
        .multilineTextAlignment(.center)
        .padding(16)
        .transition(.scaleAndBlur(anchor: .top))
    }
}

struct TutorialItemView: View {
    var animation: String
    var description: String
    var rotate: Double = 0
    var body: some View {
        VStack(spacing: 6) {
            LottieView {
                try await DotLottieFile.named(animation).animationSource
            } placeholder: {
                EmptyView()
            }
            .configuration(.init(renderingEngine: .coreAnimation))
            .playing(loopMode: .loop)
            .resizable()
            .scaledToFill()
            .frame(48)
            .rotationEffect(.degrees(rotate))
            
            Text(description)
                .font(.system(size: 12))
                .opacity(0.75)
        }
        .frame(width: 150)
    }
}
