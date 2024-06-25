//
//  UpdateButtonIconView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import SwiftUI
import Lottie

struct UpdateButtonIconView: View {
    @State private var playbackMode: LottiePlaybackMode = .paused(at: .progress(0))
    @State private var hovered = false
    @Environment(\.sparkleManager) private var sparkleManager
    var body: some View {
        LottieView {
            try await DotLottieFile.named("update").animationSource
        } placeholder: {
            EmptyView()
        }
        .configuration(.init(renderingEngine: .coreAnimation))
        .playbackMode(playbackMode)
        .animationDidFinish({ completed in
            if !completed { return }
            playbackMode = .paused(at: .progress(0))
        })
        .resizable()
        .scaledToFit()
        .padding(6)
        .scaleEffect(hovered ? 0.9 : 1.0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .contentShape(Rectangle())
        .onTapGesture {
            sparkleManager.checkForUpdates()
            LiveActivitiesManager.shared.activeLiveActivities.remove(.updateAvailable)
        }
        .onHover { hovering in
            withAnimation(ShrinkOnClick.animation) { hovered = hovering }
            if hovering, playbackMode == .paused(at: .progress(0)) {
                playbackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
            }
        }
    }
}
