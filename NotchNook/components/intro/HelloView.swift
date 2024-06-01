//
//  HelloView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI
import Lottie
import Defaults

struct HelloView: View {
    @Binding var tutorial: Bool
    @State private var step = 0
    
    var body: some View {
        VStack(spacing: 10) {
            LottieView {
                try await DotLottieFile.named("hello").animationSource
            } placeholder: {
                EmptyView()
            }
            .configuration(.init(renderingEngine: .coreAnimation))
            .playbackMode(.playing(.fromProgress(0, toProgress: 0.5, loopMode: .playOnce)))
            .resizable()
            .scaledToFill()
            .frame(width: 150, height: 30)
            
            VStack(spacing: 1) {
                if step > 0 {
                    Text("Welcome to NotchNook!").font(.system(size: 14)).opacity(0.75)
                }
                if step > 1 {
                    Text("A new way to interact with your mac").opacity(0.5)
                }
            }
            if step > 2 {
                HStack {
                    StartButton()
                    Button("See Tutorial") { withAnimation(.smooth(extraBounce: 0.15)) { tutorial.toggle() } }
                }
                .buttonStyle(ActionButton())
            }
        }
        .multilineTextAlignment(.center)
        .padding(.all, 16)
        .frame(alignment: .top)
        .transition(step == 3 ? .scaleAndBlur(anchor: .top) : .identity)
        .task {
            withAnimation(.spring.delay(2.5)) {
                step = 1
            } completion: {
                withAnimation(.spring.delay(0.5)) {
                    step = 2
                } completion: {
                    withAnimation(.spring.delay(0.5)) {
                        step = 3
                    }
                }
            }
        }
    }
}
