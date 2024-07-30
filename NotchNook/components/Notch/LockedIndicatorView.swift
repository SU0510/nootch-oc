//
//  LockedIndicatorView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/06/24.
//

import SwiftUI
import Lottie
import SmoothGradient

struct LockedIndicatorView: View {
    static let lanternSize: Double = 72
    static let iconCircleSize: Double = 32
    static let blurSize: Double = 64
    var locked: Bool
    var toggleLock: (() -> ())?
    var typing: Bool = false
    @State private var showKeyboardIcon = false
    @State private var pressing = false
    @State private var mousePos: CGPoint?
    @State private var timer: Timer?
    @State private var animateLottie = false
    @Environment(\.resignFirstResponder) private var resignFirstResponder
    
    var hovering: Bool { mousePos != nil }
    var lockedOrTyping: Bool { locked || typing }
    
    var body: some View {
        let iconColor = (lockedOrTyping ? Color.blue : Color.white)
        let rgb = NSColor(iconColor).rgb
        let colorProvider = ColorValueProvider(.init(r: rgb.0, g: rgb.1, b: rgb.2, a: iconColor.alpha))
        let iconOpacity = lockedOrTyping ? 1 : pressing ? 0.75 : 0.5
        Button {
            if typing { resignFirstResponder() } else { toggleLock?() }
        } label: {
            VStack {
                Group {
                    if showKeyboardIcon {
                        Image(systemName: "keyboard.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.blue.opacity(iconOpacity))
                    } else {
                        //                Image(systemName: showKeyboardIcon ? "keyboard.fill" : "lock.fill")
                        LottieView {
                            try await DotLottieFile.named("lock").animationSource
                        } placeholder: {
                            EmptyView()
                        }
                        .configuration(.init(renderingEngine: .coreAnimation))
                        .playbackMode(
                            animateLottie ?
                                .playing(.fromProgress(locked ? 1 : 0, toProgress: locked ? 0 : 1, loopMode: .playOnce)) : .paused(at: .progress(locked ? 0 : 1))
                        )
                        .valueProvider(colorProvider, for: colorLottieKeypath)
                        .animationDidFinish({ completed in
                            if !completed { return }
                            withAnimation { animateLottie = false }
                        })
                        .resizable()
                        .mask { Color.black.opacity(iconOpacity) }
                        .scaledToFit()
                        .frame(16)
                        .onChange(of: locked) { oldVal, newVal in
                            animateLottie = true
                        }
                    }
                }
                .transition(.scaleAndBlur(blur: 16))
            }
            .brightness(hovering ? 0.15 : 0)
            .frame(Self.iconCircleSize)
            .clipShape(Circle())
            .frame(Self.blurSize)
            .background {
                VisualEffectViews(material: .sidebar)
                    .mask {
                        Circle()
                            .fill(
                                EllipticalGradient(
                                    gradient: .smooth(
                                        from: .white.opacity(lockedOrTyping || hovering ? 1 : 0),
                                        to: .white.opacity(lockedOrTyping ? 1 : 0), curve: .easeIn
                                    ),
                                    center: UnitPoint(x: 0.5, y: 0.5)
                                )
                            )
                    }
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(lockedOrTyping ? 0.1 : 0), lineWidth: 0.5)
                            .padding(.all, 0.5)
                    }
                    .padding(lockedOrTyping ? (Self.blurSize - Self.iconCircleSize) / 2 : 0)
            }
            .scaleEffect(pressing ? 0.9 : 1)
            .background(Color.hitBox)
            .mask {
                if lockedOrTyping {
                    Color.black
                } else if let mousePos {
                    Circle()
                        .fill(
                            EllipticalGradient(
                                gradient: .smooth(
                                    from: .white.opacity(lockedOrTyping || hovering ? 1 : 0),
                                    to: .white.opacity(lockedOrTyping ? 1 : 0), curve: .easeIn
                                ),
                                center: UnitPoint(x: 0.5, y: 0.5)
                            )
                        )
                        .frame(72)
                        .position(mousePos)
                }
            }
            .contentShape(Circle())
            .onContinuousHover { phase in
                switch phase {
                    case .active(let position): mousePos = position
                    case .ended: mousePos = nil
                }
            }
            .animation(ShrinkOnClick.animation, value: pressing)
            .animation(.smooth(duration: 0.15), value: hovering)
            .animation(.snappy(duration: 0.3, extraBounce: 0.175), value: lockedOrTyping)
        }
        .buttonStyle(BindStatesStyle(pressing: $pressing))
        .onChange(of: typing) { oldVal, newVal in
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: locked || newVal ? 0 : 0.3, repeats: false) { _ in
                withAnimation(!locked && newVal ? nil : .bouncySmooth) { self.showKeyboardIcon = newVal }
            }
        }
    }
}
