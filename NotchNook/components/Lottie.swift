//
//  Lottie.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI
import Lottie

let colorLottieKeypath = AnimationKeypath(keypath: "**.Color")
let emptyColorLottieKeypath = AnimationKeypath(keypath: "**.EmptyKeyPath")

/// Like LottieViewWrapper but specifically for non-animated icons
struct StillLottieViewWrapper: View {
    var animationName: String
    var size: Double
    var color: Color
    var progress: Double
    
    init(_ animationName: String, fontSize: Double = 16, color: Color = .primary, progress: Double = 1) {
        self.animationName = animationName
        self.size = fontSize * 1.2
        self.color = color
        self.progress = progress
    }
    
    var body: some View {
        let actualColor = NSColor(color)
        let rgb = actualColor.rgb
        let colorProvider = ColorValueProvider(.init(r: rgb.0, g: rgb.1, b: rgb.2, a: actualColor.alphaComponent))
        
        LottieView(animation: .named(animationName))
            .playbackMode(.paused(at: .progress(progress)))
            .valueProvider(colorProvider, for: colorLottieKeypath)
            .configure { val in
                val.configuration = .init(renderingEngine: .coreAnimation)
                val.shouldRasterizeWhenIdle = true
            }
            .resizable()
            .frame(size)
    }
}

/// Wraps a LottieView to give it more options and make it easier to work with
struct LottieViewWrapper: View {
    let animationName: String
    let size: CGSize
    let loopDelay: Double?
    let initialDelay: Double
    let skipInitialProgress: Double
    let color: Color?
    let animationSupportsSwitching: Bool
    let contentMode: ContentMode
    
    @State private var playbackMode: LottiePlaybackMode
    @State private var actualAnimationName: String
    @State private var waitingForSwitching = false
    @State private var firstAppear = true
    @State private var id = UUID().uuidString
    
    init(
        _ animationName: String,
        size: Double,
        loopDelay: Double? = nil,
        initialDelay: Double = 0,
        skipInitialProgress: Double = 0,
        color: Color? = .accentColor, animationSupportsSwitching: Bool = false,
        contentMode: ContentMode = .fit
    ) {
        self.animationName = animationName
        self.size = .init(width: size, height: size)
        self._playbackMode = .init(initialValue: .paused(at: .progress(skipInitialProgress)))
        self._actualAnimationName = .init(initialValue: animationName)
        self.loopDelay = loopDelay
        self.skipInitialProgress = skipInitialProgress
        self.initialDelay = initialDelay
        self.color = color
        self.animationSupportsSwitching = animationSupportsSwitching
        self.contentMode = contentMode
    }
    
    init(
        _ animationName: String,
        size: CGSize,
        loopDelay: Double? = nil,
        initialDelay: Double = 0,
        skipInitialProgress: Double = 0,
        color: Color? = .accentColor,
        animationSupportsSwitching: Bool = false,
        contentMode: ContentMode = .fit
    ) {
        self.animationName = animationName
        self.size = size
        self._playbackMode = .init(initialValue: .paused(at: .progress(skipInitialProgress)))
        self._actualAnimationName = .init(initialValue: animationName)
        self.loopDelay = loopDelay
        self.skipInitialProgress = skipInitialProgress
        self.initialDelay = initialDelay
        self.color = color
        self.animationSupportsSwitching = animationSupportsSwitching
        self.contentMode = contentMode
    }
    
    var body: some View {
        let actualColor = NSColor(color ?? .nonShockingWhite)
        let rgb = actualColor.rgb
        let colorProvider = ColorValueProvider(.init(r: rgb.0, g: rgb.1, b: rgb.2, a: actualColor.alphaComponent))
        
        LottieView(animation: .named(animationName))
            .playbackMode(playbackMode)
            .valueProvider(colorProvider, for: color == nil ? emptyColorLottieKeypath : colorLottieKeypath)
            .configuration(.init(renderingEngine: .coreAnimation))
            .animationDidFinish({ completed in
                guard completed else { return }
                if waitingForSwitching {
                    waitingForSwitching = false
                    playbackMode = .paused
                    withAnimation(.spring) {
                        actualAnimationName = animationName
                    }
                    doAfter(0.2) { playbackMode = .playing(.toProgress(1, loopMode: .playOnce)) }
                } else if let loopDelay {
                    playbackMode = .paused(at: .time(0))
                    doAfter(loopDelay) {
                        playbackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                    }
                }
            })
            .onAppear {
                if firstAppear {
                    doAfter(initialDelay) {
                        playbackMode = .playing(.fromProgress(skipInitialProgress, toProgress: 1, loopMode: .playOnce))
                    }
                }
            }
            .aspectRatio(contentMode: contentMode)
            .frame(size)
            .transition(animationSupportsSwitching ? .identity : .scaleAndBlur)
            .id("\(id)-\(actualAnimationName)")
            .onChange(of: animationName) { _, newAnimName in
                if animationSupportsSwitching {
                    waitingForSwitching = true
                    playbackMode = .playing(.toProgress(0, loopMode: .playOnce))
                } else {
                    playbackMode = .paused(at: .time(0))
                    withAnimation(.spring) {
                        actualAnimationName = newAnimName
                    }
                    doAfter(0.4) {
                        playbackMode = .playing(.toProgress(1, loopMode: .playOnce))
                    }
                }
            }
    }
}
