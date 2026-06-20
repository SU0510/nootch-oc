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
//  Reorganized 2026-06-20 (Phase 1 of the new creator layout):
//   • No header bar. The widget is now TWO columns side by side:
//       LEFT  — the wheels (selection lens + scrolling digits + glass pill),
//               filling ALL remaining width and height.
//       RIGHT — a fixed-width column of perfect CIRCLES: quick-timer presets
//               stacked above a larger Play circle pinned to the bottom.
//   • The close (xmark) lives as a subtle top-left overlay on the whole widget,
//     clear of the notch top-bar chrome (topSafe).
//   • Nothing clips: the glass pill bleeds shadow/edge-highlight outside its own
//     rect, so we keep insets/allowances and never put `.clipped()` on an
//     ancestor. The whole block fills the frame but stays inside its bounds.
//

import SwiftUI
import AppKit
import Metal

struct TimerCreatorView: View {
    @Binding var isShowing: Bool
    var topSafe: CGFloat
    var bottomLeadingSafe: CGFloat
    var bottomTrailingSafe: CGFloat

    @Environment(\.timerWidgetSettings) private var prefs

    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    /// Which wheel currently has scroll focus (0=h, 1=m, 2=s). Drives the
    /// sliding glass indicator, like the selected tab in an iOS nav bar.
    @State private var focusedWheel: Int = 1

    private let quickPresets: [(label: String, seconds: Int)] = [
        ("1m",   60),
        ("5m",   300),
        ("10m",  600),
        ("25m",  1500),
        ("1h",   3600),
    ]

    private var totalSeconds: Int { hours * 3600 + minutes * 60 + seconds }

    fileprivate static let rowHeight: CGFloat = 30
    fileprivate static let visibleRows: CGFloat = 4
    fileprivate static var wheelHeight: CGFloat { CGFloat(visibleRows) * rowHeight } // 72
    /// Selection lens wraps ONLY the center row (the value being set).
    fileprivate static let selectionHeight: CGFloat = rowHeight  // 24
    /// Focus pill is a touch narrower than its column and a touch taller than
    /// the dark track, so it reads as a distinct floating element.
    fileprivate static let indicatorWidthInset: CGFloat = -10
    fileprivate static let indicatorHeightBump: CGFloat = 18
    /// Gap between the 3 wheels. (Was also the gap to the old button column,
    /// which is gone — the button column is now a separate sibling, see body.)
    /// Reduced from 8 → 5 so the digits sit closer together.
    fileprivate static let wheelGap: CGFloat = 5

    // MARK: Right button column (perfect circles)

    /// Diameter of the primary Play circle.
    fileprivate static let playDiameter: CGFloat = 38
    /// Diameter of each quick-preset circle (smaller than Play, same language).
    fileprivate static let presetDiameter: CGFloat = 26
    /// Vertical gap between stacked circles in the right column.
    fileprivate static let circleGap: CGFloat = 6
    /// Allowance around the button column so the circles' fills/press-scale and
    /// any soft shadow have room and never get visually clipped by the edge.
    fileprivate static let columnInset: CGFloat = 6
    /// Breathing room kept on every side so the glass pill's shadow + edge
    /// highlight (which bleed OUTSIDE the pill rect) are never clipped.
    fileprivate static let glassAllowance: CGFloat = 4

    var body: some View {
        // TWO columns: wheels (fill) on the left, a fixed-width circle column on
        // the right. topSafe clearance keeps everything below the notch chrome.
        // No `.clipped()` anywhere on the path — the glass pill and the circle
        // fills cast highlights/shadows that must be free to bleed outside.
        HStack(alignment: .center, spacing: Self.wheelGap) {
            wheelStack
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            buttonColumn
                .frame(width: Self.playDiameter + Self.columnInset * 2)
        }
        .padding(.top, topSafe)                         // clear notch top-bar buttons
        .padding(.leading, max(Self.glassAllowance, bottomLeadingSafe * 0.4))
        .padding(.trailing, max(Self.glassAllowance, bottomTrailingSafe * 0.4))
        .padding(.bottom, 10)                           // off the widget's bottom edge
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Subtle close affordance, top-left, clear of the notch top-bar chrome.
        .overlay(alignment: .topLeading) { closeButton }
    }

    // MARK: - Close (subtle top-left overlay)

    private var closeButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                isShowing = false
            }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(width: 16, height: 16)
                .background(
                    Circle().fill(Color.white.opacity(0.10))
                )
        }
        .buttonStyle(ShrinkOnPressButtonStyle())
        // Sit just inside the top-left corner, below the notch top-bar chrome.
        .padding(.top, topSafe)
        .padding(.leading, Self.glassAllowance)
    }

    // MARK: - Wheels + glass pill

    private var wheelStack: some View {
        // The wheel group keeps its intrinsic 72pt height (NumberWheel owns that)
        // but is centered inside the LEFT column, which fills all remaining width
        // and height. colW is now derived from the 3-wheel width ONLY (the button
        // column is a separate sibling, no longer one of four equal columns), so
        // the sliding glass pill stays aligned with its wheel.
        GeometryReader { geo in
            let colW = (geo.size.width - 2 * Self.wheelGap) / 3
            ZStack {
                // Exact iOS 26 nav-bar selector stack, bottom → top:
                //   dark track → wheel digit → refraction-lens pill.
                // The lens is a true zero-blur refraction lens (Metal), so the
                // wheel digit BEHIND it reads perfectly through the clear glass —
                // exactly like the tab-bar selector gliding over a tab label.
                // No crisp-digit overlay: a single wheel digit, one lens passing
                // over it, refracting whatever it covers and carrying nothing.
                selectionLens                    // dark #19191B track
                wheelsRow                        // scrolling digits — refracted BEHIND the lens
                focusIndicator(colW: colW)       // lens pill — moves/stretches alone
            }
            // Fixed-height wheel group (NumberWheel's 72pt), then centered in the
            // full left column so it fills the available width/height visually.
            .frame(width: geo.size.width, height: Self.wheelHeight)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
    }

    // MARK: - Right button column (presets stacked above Play — perfect circles)

    private var buttonColumn: some View {
        // Play is pinned to the BOTTOM (aligned with the wheels' baseline feel);
        // as many quick-preset circles as physically FIT stack above it, top-down.
        // GeometryReader so the preset count adapts to the widget's real height.
        GeometryReader { geo in
            // Height left for presets once Play + its gap are reserved.
            let presetsArea = geo.size.height - Self.playDiameter - Self.circleGap
            let step = Self.presetDiameter + Self.circleGap
            // Fit as many presets as the column allows, in order (never more than
            // we have). max(0,…) guards a column too short for any preset.
            let maxFit = step > 0 ? max(0, Int((presetsArea + Self.circleGap) / step)) : 0
            let shown = quickPresets.prefix(min(maxFit, quickPresets.count))

            VStack(spacing: Self.circleGap) {
                ForEach(Array(shown), id: \.seconds) { preset in
                    presetCircle(preset)
                }
                Spacer(minLength: 0)
                playCircle
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
        }
    }

    /// A quick-timer preset rendered as a small circle (same language as Play).
    private func presetCircle(_ preset: (label: String, seconds: Int)) -> some View {
        Button {
            applyPreset(preset.seconds)
        } label: {
            Text(preset.label)
                .font(.system(size: 9, weight: .semibold).monospacedDigit())
                .foregroundStyle(Color.white.opacity(0.85))
                .frame(width: Self.presetDiameter, height: Self.presetDiameter)
                .background(Circle().fill(Color.white.opacity(0.12)))
        }
        .buttonStyle(ShrinkOnPressButtonStyle())
    }

    /// The primary Play action — a perfect accent-tinted circle, dimmed while the
    /// duration is still zero (keeps the original disabled/commit behavior).
    private var playCircle: some View {
        Button {
            commitIfValid()
        } label: {
            Image(systemName: "play.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: Self.playDiameter, height: Self.playDiameter)
                .background(
                    Circle().fill(Color.accentColor.opacity(totalSeconds > 0 ? 0.9 : 0.22))
                )
        }
        .buttonStyle(ShrinkOnPressButtonStyle())
        .disabled(totalSeconds <= 0)
        .opacity(totalSeconds <= 0 ? 0.55 : 1)
    }

    /// Dark #19191B track wrapping the center row across ALL 3 wheels. SOLID,
    /// not glass: glass cannot sample other glass outside a shared container, so
    /// the focus pill (the real Liquid Glass) is kept the ONLY glass element —
    /// it then refracts both the digits and this dark track behind it cleanly.
    private var selectionLens: some View {
        Capsule(style: .continuous)
            .fill(Color.hex("#19191B"))
            .frame(height: Self.selectionHeight)
            .frame(maxWidth: .infinity)
            .allowsHitTesting(false)
    }

    /// Center x of the focused column, measured from the wheel-group's left
    /// edge. Columns are colW wide, separated by wheelGap.
    private func columnCenterX(colW: CGFloat) -> CGFloat {
        let step = colW + Self.wheelGap
        return colW / 2 + CGFloat(focusedWheel) * step
    }

    private func pillWidth(colW: CGFloat) -> CGFloat { colW - Self.indicatorWidthInset * 2 }
    private var pillHeight: CGFloat { Self.selectionHeight + Self.indicatorHeightBump }

    // The focus pill — ONE persistent Liquid Glass capsule that SLIDES between
    // wheels by changing its x-offset, exactly like the iOS 26 nav-bar selector.
    // A single mounted view that just moves re-runs the glass shader every frame,
    // so the digit behind it visibly bends as it travels (glassEffectID morph
    // froze the backdrop instead). ONE pill only — "glass cannot sample other
    // glass", so a second stacked pill would break the material.
    //
    // The "expand while moving, settle when stopped" liquid signature is a
    // keyframe pulse on scale, retriggered on every focus change. The crisp
    // number is NOT embedded here — it rides in its own layer (crispDigitIndicator)
    // so the bubble can move and stretch on its own without dragging the digit.
    @ViewBuilder
    private func focusIndicator(colW: CGFloat) -> some View {
        let centerX = columnCenterX(colW: colW)
        let pillW = pillWidth(colW: colW)
        let pillH = pillHeight

        pill(width: pillW, height: pillH)
            // Position from the leading edge, then nudge by half the group so
            // offset 0 == group center; centerX is already absolute-from-left.
            .frame(width: pillW, height: pillH)
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(x: centerX - pillW / 2)
            .animation(.spring(response: 0.42, dampingFraction: 0.7), value: focusedWheel)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private func pill(width: CGFloat, height: CGFloat) -> some View {
        // A TRUE refraction lens (Metal), ported from LiquidGlassKit — the same
        // technique as iOS 26's private `_UILiquidLensView` tab-bar selector.
        // Unlike AppKit's `NSGlassEffectView` (frosted: always Gaussian-blurs its
        // backdrop), this lens has ZERO blur — it only bends light at the edges
        // and passes the center through crisp. That's why no crisp-digit overlay
        // is needed: the wheel digit BEHIND the lens reads perfectly through it.
        Group {
            if #available(macOS 26, *), NativeGlassPill.isAvailable {
                // macOS 26+: the REAL private Liquid Glass stack (CABackdropLayer +
                // glassBackground), the same one SwiftUI's `.glassEffect()` uses.
                // Runs in the WindowServer (GPU, off the main thread) and samples
                // the composited backdrop at the pill's true screen position — so
                // it's both far cheaper than the Metal lens AND world-anchored (no
                // background drift). See NativeGlassPill.swift.
                NativeGlassPill(cornerRadius: height / 2)
            } else if MTLCreateSystemDefaultDevice() != nil {
                // macOS < 26 (or private classes unavailable): the Metal refraction
                // lens fallback (per-frame capture; world-anchored this session).
                LiquidLensPill(cornerRadius: height / 2)
            } else {
                // No-Metal fallback: a hairline capsule over a dimming fill.
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    )
            }
        }
        .keyframeAnimator(initialValue: PillStretch(), trigger: focusedWheel) { view, s in
            view.scaleEffect(x: s.scaleX, y: s.scaleY, anchor: .center)
        } keyframes: { _ in
            KeyframeTrack(\.scaleX) {
                CubicKeyframe(1.0,  duration: 0.001)
                CubicKeyframe(1.35, duration: 0.18)   // expand mid-travel
                SpringKeyframe(1.0, duration: 0.32, spring: .bouncy)  // settle
            }
            KeyframeTrack(\.scaleY) {
                CubicKeyframe(1.0,  duration: 0.001)
                CubicKeyframe(0.88, duration: 0.18)   // squash while stretched
                SpringKeyframe(1.0, duration: 0.32, spring: .bouncy)
            }
        }
    }

    private var wheelsRow: some View {
        HStack(spacing: 0) {
            NumberWheel(value: $hours,   range: 0...23, suffix: "h",
                        index: 0, focusedWheel: $focusedWheel)
            separator
            NumberWheel(value: $minutes, range: 0...59, suffix: "m",
                        index: 1, focusedWheel: $focusedWheel)
            separator
            NumberWheel(value: $seconds, range: 0...59, suffix: "s",
                        index: 2, focusedWheel: $focusedWheel)
        }
    }

    private var separator: some View {
        Text(":")
            .font(.system(size: 18, weight: .semibold).monospacedDigit())
            .foregroundStyle(Color.white.opacity(0.32))
            .frame(width: Self.wheelGap)
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

}

// MARK: - Pill stretch (keyframe state)

/// Drives the focus pill's stretch/squash pulse as it slides between wheels.
private struct PillStretch {
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
}

// MARK: - NumberWheel

private struct NumberWheel: View {
    @Binding var value: Int
    var range: ClosedRange<Int>
    var suffix: String
    var index: Int
    @Binding var focusedWheel: Int

    private var rowHeight: CGFloat   { TimerCreatorView.rowHeight }
    private var wheelHeight: CGFloat { TimerCreatorView.wheelHeight }

    @State private var scrollPosition: Int?

    init(value: Binding<Int>, range: ClosedRange<Int>, suffix: String,
         index: Int, focusedWheel: Binding<Int>) {
        self._value = value
        self.range = range
        self.suffix = suffix
        self.index = index
        self._focusedWheel = focusedWheel
        // Start already centered on the current value so the bold/selected row
        // lands on the center line at first render (not pinned at the top when
        // the value is 0). Setting scrollPosition in onAppear was racing layout.
        self._scrollPosition = State(initialValue: value.wrappedValue)
    }

    /// Claim focus for this wheel inside an explicit withAnimation so the
    /// glassEffectID indicator MORPHS to this column (implicit animation only
    /// moves frames; the liquid morph needs the explicit transaction).
    private func focusWheel() {
        guard focusedWheel != index else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
            focusedWheel = index
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            // Non-lazy VStack: ranges are short (≤60), so materializing every
            // row up front is cheap and makes the initial scrollPosition land
            // exactly on `value`. With LazyVStack the target row often wasn't
            // built yet on first render, so a non-zero default (minutes=5)
            // mis-settled one row off (→ 4m). Zero defaults hid it (top edge).
            VStack(spacing: 0) {
                ForEach(range, id: \.self) { n in
                    rowLabel(n)
                        .frame(height: rowHeight)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        // Tap any row to select it: the row above the center
                        // scrolls up, the row below scrolls down. onChange(of:
                        // value) animates scrollPosition to land it centered.
                        // simultaneousGesture (not onTapGesture) so the tap runs
                        // ALONGSIDE the ScrollView's own gesture — a plain
                        // onTapGesture loses the click to the scroll recognizer.
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                focusWheel()
                                guard n != value else { return }
                                value = n
                                vibrate()
                            }
                        )
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
        .contentShape(Rectangle())
        // Focus follows the mouse, like selecting a tab in an iOS nav bar — the
        // glass indicator slides to whichever wheel the cursor is over.
        .onHover { inside in
            if inside { focusWheel() }
        }
        .onAppear { scrollPosition = value }
        .onChange(of: scrollPosition) { _, new in
            guard let new else { return }
            if new != value {
                value = new
                vibrate()
            }
            // Scrolling a wheel also claims focus.
            focusWheel()
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
                    weight: isCenter ? .semibold : .regular
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
            // Deeper curve so the off-center rows read clearly smaller than the
            // selected one (was 0.18 → too subtle).
            return content.scaleEffect(1.0 - t * 0.34)
        }
    }
}

// MARK: - Custom button style (bounded extent — no glass halo)

private struct ShrinkOnPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(duration: 0.15), value: configuration.isPressed)
    }
}
