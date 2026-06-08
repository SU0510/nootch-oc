//
//  TimerCreatorView.swift
//  NotchNook
//
//  Created by Wren on 25/05/26.
//  Redesigned 2026-05-30:
//   • Real Liquid Glass on the picker pill (macOS 26) with a thick-material
//     fallback for older macOS. Buttons use plain, bounded capsules so their
//     visual extent stays inside the widget frame (Apple's `.buttonStyle(.glass)`
//     adds halo/shadow outside the content bounds and gets clipped in tight
//     widget layouts like this one).
//   • Centered digit is rendered bolder/brighter so it reads through the frost.
//   • All digits same size; per-row scale curve fakes optical lensing.
//

import SwiftUI

struct TimerCreatorView: View {
    @Binding var isShowing: Bool
    var topSafe: CGFloat
    var bottomLeadingSafe: CGFloat
    var bottomTrailingSafe: CGFloat

    @Environment(\.timerWidgetSettings) private var prefs

    @State private var hours: Int = 0
    @State private var minutes: Int = 5
    @State private var seconds: Int = 0

    private let quickPresets: [(label: String, seconds: Int)] = [
        ("1m",   60),
        ("5m",   300),
        ("10m",  600),
        ("25m",  1500),
        ("1h",   3600),
    ]

    private var totalSeconds: Int { hours * 3600 + minutes * 60 + seconds }

    fileprivate static let rowHeight: CGFloat = 24
    fileprivate static let visibleRows: Int = 3
    fileprivate static var wheelHeight: CGFloat { CGFloat(visibleRows) * rowHeight } // 72
    fileprivate static let pillHeight: CGFloat = 30

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: topSafe)

            topRow
                .padding(.horizontal, 10)
                .padding(.top, 2)

            Spacer(minLength: 2)

            wheelStack
                .padding(.horizontal, 10)

            Spacer(minLength: 2)

            bottomBar
                .padding(.leading, bottomLeadingSafe)
                .padding(.trailing, bottomTrailingSafe)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Wheels + glass pill

    private var wheelStack: some View {
        ZStack {
            HStack(spacing: 0) {
                NumberWheel(value: $hours,   range: 0...23, suffix: "h")
                separator
                NumberWheel(value: $minutes, range: 0...59, suffix: "m")
                separator
                NumberWheel(value: $seconds, range: 0...59, suffix: "s")
            }

            glassPill
                .allowsHitTesting(false)
        }
        .frame(height: Self.wheelHeight)
    }

    @ViewBuilder
    private var glassPill: some View {
        if #available(macOS 26.0, *) {
            // Real Liquid Glass — the one true glass element in this view.
            // `.clear` variant is designed to overlay content while keeping
            // what's underneath readable.
            Color.clear
                .frame(height: Self.pillHeight)
                .frame(maxWidth: .infinity)
                .glassEffect(.clear, in: Capsule(style: .continuous))
        } else {
            Capsule(style: .continuous)
                .fill(.thickMaterial)
                .frame(height: Self.pillHeight)
                .frame(maxWidth: .infinity)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.45),
                                    Color.white.opacity(0.06),
                                    Color.white.opacity(0.18),
                                ],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 0.7
                        )
                )
        }
    }

    private var separator: some View {
        Text(":")
            .font(.system(size: 18, weight: .semibold).monospacedDigit())
            .foregroundStyle(Color.white.opacity(0.32))
            .frame(width: 8)
    }

    // MARK: - Top row (title + preset chips, plain bounded capsules)

    private var topRow: some View {
        HStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.75))
                Text("Timer")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
            }

            Spacer(minLength: 4)

            HStack(spacing: 3) {
                ForEach(quickPresets, id: \.seconds) { preset in
                    Button(preset.label) { applyPreset(preset.seconds) }
                        .buttonStyle(ChipButtonStyle())
                }
            }
        }
    }

    // MARK: - Bottom bar (close + start, plain bounded capsules)

    private var bottomBar: some View {
        HStack(spacing: 6) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                    isShowing = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(ShrinkOnPressButtonStyle())

            Spacer(minLength: 0)

            Button {
                commitIfValid()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(formatted(totalSeconds))
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.accentColor.opacity(totalSeconds > 0 ? 0.9 : 0.22))
                )
            }
            .buttonStyle(ShrinkOnPressButtonStyle())
            .disabled(totalSeconds <= 0)
            .opacity(totalSeconds <= 0 ? 0.55 : 1)
        }
    }

    // MARK: - Actions

    private func applyPreset(_ secs: Int) {
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            hours = h
            minutes = m
            seconds = s
        }
        vibrate()
    }

    private func commitIfValid() {
        guard totalSeconds > 0 else { return }
        let effectiveLabel = prefs.defaultLabel
        NookTimersStore.shared.add(label: effectiveLabel, totalSeconds: totalSeconds)
        vibrate()
        withAnimation(.spring) { isShowing = false }
    }

    private func formatted(_ s: Int) -> String {
        if s == 0 { return "Start" }
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%d:%02d", m, sec)
    }
}

// MARK: - NumberWheel

private struct NumberWheel: View {
    @Binding var value: Int
    var range: ClosedRange<Int>
    var suffix: String

    private var rowHeight: CGFloat   { TimerCreatorView.rowHeight }
    private var wheelHeight: CGFloat { TimerCreatorView.wheelHeight }

    @State private var scrollPosition: Int?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(range, id: \.self) { n in
                    rowLabel(n)
                        .frame(height: rowHeight)
                        .id(n)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .contentMargins(.vertical, (wheelHeight - rowHeight) / 2, for: .scrollContent)
        .frame(height: wheelHeight)
        .frame(maxWidth: .infinity)
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear,                location: 0),
                    .init(color: .black.opacity(0.55),  location: 0.18),
                    .init(color: .black,                location: 0.5),
                    .init(color: .black.opacity(0.55),  location: 0.82),
                    .init(color: .clear,                location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
        )
        .onAppear { scrollPosition = value }
        .onChange(of: scrollPosition) { _, new in
            guard let new else { return }
            if new != value {
                value = new
                vibrate()
            }
        }
        .onChange(of: value) { _, new in
            if scrollPosition != new {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    scrollPosition = new
                }
            }
        }
    }

    @ViewBuilder
    private func rowLabel(_ n: Int) -> some View {
        // Center row reads through the glass — bump weight + opacity so the
        // frost doesn't make the SELECTED digit dimmer than its neighbours.
        let isCenter = n == value
        HStack(spacing: 2) {
            Text(String(format: "%02d", n))
                .font(.system(
                    size: 20,
                    weight: isCenter ? .heavy : .medium
                ).monospacedDigit())
                .foregroundStyle(isCenter ? Color.white : Color.white.opacity(0.5))
            Text(suffix)
                .font(.system(size: 11, weight: isCenter ? .semibold : .medium))
                .foregroundStyle(isCenter ? Color.white.opacity(0.8) : Color.white.opacity(0.28))
                .offset(y: 3)
        }
        .animation(.easeOut(duration: 0.18), value: isCenter)
        .visualEffect { content, proxy in
            // Distance from this row's center to scroll-view's center, in
            // a CONSISTENT coord space (both in MY coords).
            let scvBounds = proxy.bounds(of: .scrollView) ?? .zero
            let scvCenterInMyCoords = scvBounds.midY
            let myCenter = proxy.size.height / 2
            let dy = abs(scvCenterInMyCoords - myCenter)
            let maxDy = TimerCreatorView.wheelHeight / 2
            let t = min(1, dy / maxDy)
            return content.scaleEffect(1.0 - t * 0.18)
        }
    }
}

// MARK: - Custom button styles (bounded extent — no glass halo)

private struct ChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold).monospacedDigit())
            .foregroundStyle(Color.white.opacity(configuration.isPressed ? 1 : 0.85))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.25 : 0.12))
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(duration: 0.15), value: configuration.isPressed)
    }
}

private struct ShrinkOnPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(duration: 0.15), value: configuration.isPressed)
    }
}
