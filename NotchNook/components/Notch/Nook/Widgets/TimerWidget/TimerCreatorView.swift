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
import AppKit

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

    /// The value living on the focused wheel. Rendered as a crisp glyph ON the
    /// glass (the "front" number) while the scrolling wheel digit sits BEHIND
    /// the glass and gets refracted — two numbers, one on each side of the pill.
    private var focusedValue: Int {
        switch focusedWheel {
        case 0:  return hours
        case 2:  return seconds
        default: return minutes
        }
    }

    fileprivate static let rowHeight: CGFloat = 24
    fileprivate static let visibleRows: Int = 3
    fileprivate static var wheelHeight: CGFloat { CGFloat(visibleRows) * rowHeight } // 72
    /// Selection lens wraps ONLY the center row (the value being set).
    fileprivate static let selectionHeight: CGFloat = rowHeight  // 24
    /// Focus pill is a touch narrower than its column and a touch taller than
    /// the dark track, so it reads as a distinct floating element.
    fileprivate static let indicatorWidthInset: CGFloat = 7
    fileprivate static let indicatorHeightBump: CGFloat = 8
    /// Gap between wheels (and between the last wheel and the button column).
    /// Reduced from 8 → 5 so the digits sit closer together.
    fileprivate static let wheelGap: CGFloat = 5
    /// Compact height for the cancel/start buttons (they don't fill the column).
    fileprivate static let buttonHeight: CGFloat = 26

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: topSafe)

            topRow
                .padding(.horizontal, 10)
                .padding(.top, 2)

            // Small FIXED gap, then pool all slack at the bottom (Spacer below).
            // Top-aligning kills the centering that opened a gap under topRow and
            // read as top padding; the wheels now sit right under the title.
            Color.clear.frame(height: 4)

            wheelStack
                .padding(.leading, 10)
                .padding(.trailing, bottomTrailingSafe)

            Spacer(minLength: 0)
        }
        .padding(.bottom, 10)   // keep the block off the widget's bottom edge
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Wheels + glass pill

    private var wheelStack: some View {
        // 4 equal columns: 3 wheels + a button column the width of one wheel.
        // GeometryReader so the button column is EXACTLY one wheel wide and the
        // wheel group keeps its 3 columns + 2 gaps aligned with the indicator.
        GeometryReader { geo in
            let colW = (geo.size.width - 3 * Self.wheelGap) / 4
            let wheelsW = colW * 3 + Self.wheelGap * 2
            HStack(spacing: Self.wheelGap) {
                // Exact iOS 26 nav-bar selector stack, bottom → top:
                //   dark track → wheel digit (lensed THROUGH the glass) → glass pill.
                // The CRISP focused digit is NOT a separate overlay — it's the
                // glass pill's own contentView (embedded in the glass), so the
                // material never blurs it, exactly like the tab-bar selector's
                // label. Only the wheel digit behind the glass gets lensed.
                ZStack {
                    selectionLens                    // dark #19191B track
                    wheelsRow                        // scrolling digits — lensed BEHIND the glass
                    focusIndicator(colW: colW)       // glass pill (dimmed backing) — moves/stretches alone
                    crispDigitIndicator(colW: colW)  // crisp focused number — independent layer, no stretch
                }
                .frame(width: wheelsW, height: Self.wheelHeight)

                buttonColumn
                    .frame(width: colW, height: Self.wheelHeight)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(height: Self.wheelHeight)
    }

    // MARK: - Button column (cancel on top, start on bottom — one wheel wide)

    private var buttonColumn: some View {
        // Small fixed-height buttons pinned to the BOTTOM of the column (empty
        // space above), aligned with the bottom of the wheels.
        VStack(spacing: Self.wheelGap) {
            Spacer(minLength: 0)

            // Cancel (top)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                    isShowing = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                    )
            }
            .buttonStyle(ShrinkOnPressButtonStyle())

            // Start (bottom)
            Button {
                commitIfValid()
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.accentColor.opacity(totalSeconds > 0 ? 0.9 : 0.22))
                    )
            }
            .buttonStyle(ShrinkOnPressButtonStyle())
            .disabled(totalSeconds <= 0)
            .opacity(totalSeconds <= 0 ? 0.55 : 1)
        }
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

    /// The crisp focused number, drawn in its OWN layer on top of the glass — NOT
    /// embedded inside the pill. This decouples the digit from the bubble: the
    /// glass capsule can slide and stretch/squash on its own while the number
    /// simply glides to the focused column center (a calm spring, no keyframe
    /// pulse), so the value stays steady and readable as the bubble travels.
    @ViewBuilder
    private func crispDigitIndicator(colW: CGFloat) -> some View {
        let centerX = columnCenterX(colW: colW)
        let pillW = pillWidth(colW: colW)

        crispDigit
            .frame(width: pillW, height: pillHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(x: centerX - pillW / 2)
            .animation(.spring(response: 0.42, dampingFraction: 0.7), value: focusedWheel)
            .allowsHitTesting(false)
    }

    /// The crisp focused value. Rides above the glass as foreground content, so
    /// the material never blurs it — exactly how the tab-bar selector keeps its
    /// label sharp. The wheel digit behind the glass is the only thing lensed.
    private var crispDigit: some View {
        Text(String(format: "%02d", focusedValue))
            .font(.system(size: 20, weight: .semibold).monospacedDigit())
            .foregroundStyle(Color.white)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: focusedValue)
            // Fill + center inside the host so the digit sits in the middle of
            // the glass instead of pinning to a corner.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func pill(width: CGFloat, height: CGFloat) -> some View {
        // Apple's REAL native Liquid Glass — the AppKit `NSGlassEffectView`, the
        // exact engine the system uses. `.clear` style + nil tint = the most
        // transparent, distortion-forward variant. No borders, no sheen, no tint
        // — pure native glass, just like the tab-bar selector. The crisp digit is
        // drawn in a SEPARATE layer (crispDigitIndicator), so this bubble owns
        // only its own motion/stretch. A subtle dark fill sits BEHIND the glass
        // to dim whatever it travels over, giving the capsule a clearer body.
        Group {
            if #available(macOS 26.0, *) {
                LiquidGlassPill(cornerRadius: height / 2) {
                    // Dimming backdrop embedded as the glass's content: darkens
                    // the digit/track beneath the bubble (≈0.3 black overlay).
                    Capsule(style: .continuous)
                        .fill(Color.black.opacity(0.3))
                }
            } else {
                // Pre-26 fallback: a hairline capsule over a dimming fill.
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

// MARK: - Real Liquid Glass (AppKit) bridge

/// Apple's native `NSGlassEffectView` (macOS 26) — the genuine Liquid Glass
/// engine, not SwiftUI's `.glassEffect`. Two things ride on it:
///   • the digit BEHIND the pill in the window → lensed by the material
///   • the crisp digit, set as the view's `contentView` → embedded INSIDE the
///     glass as foreground content, so the material never blurs it. This is the
///     exact trick the tab-bar selector uses to keep its label sharp.
/// Public API only: `style = .clear` (most transparent, distortion-forward),
/// `tintColor = nil` (zero added color). The crisp content is hosted via an
/// `NSHostingView` and updated each pass so the digit value stays live.
@available(macOS 26.0, *)
private struct LiquidGlassPill<Content: View>: NSViewRepresentable {
    var cornerRadius: CGFloat
    @ViewBuilder var content: () -> Content

    func makeNSView(context: Context) -> NSGlassEffectView {
        let v = NSGlassEffectView()
        v.cornerRadius = cornerRadius
        v.tintColor = nil               // no added color — pure glass
        v.style = .clear                // most transparent / most distortion

        // The crisp digit embedded as the glass's own content (foreground —
        // never blurred). Transparent host so only the text shows on the glass.
        let host = NSHostingView(rootView: AnyView(content()))
        host.translatesAutoresizingMaskIntoConstraints = false
        context.coordinator.host = host
        v.contentView = host
        // Pin the host to FILL the glass — otherwise NSGlassEffectView sizes the
        // glass down to the tiny text and you get a bubble around the digit.
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            host.topAnchor.constraint(equalTo: v.topAnchor),
            host.bottomAnchor.constraint(equalTo: v.bottomAnchor),
        ])

        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    func updateNSView(_ v: NSGlassEffectView, context: Context) {
        v.cornerRadius = cornerRadius
        v.tintColor = nil
        v.style = .clear
        // Push the latest digit value into the embedded host.
        context.coordinator.host?.rootView = AnyView(content())
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var host: NSHostingView<AnyView>?
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
