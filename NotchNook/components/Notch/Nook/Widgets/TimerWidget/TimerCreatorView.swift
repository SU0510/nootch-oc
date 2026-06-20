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

    /// Which wheel currently has scroll focus (0=h, 1=m, 2=s). This is the
    /// *locked* selection — the wheel the pill has magnetically snapped to.
    /// Scroll/tap/hover-snap all funnel through here, and it triggers the
    /// focus stretch-pulse on the glass pill.
    @State private var focusedWheel: Int = 1

    // MARK: Live pill plumbing (mouse-follow + scroll deformation)
    //
    // The glass pill no longer jumps discretely to `columnCenterX(focusedWheel)`.
    // Instead a single continuous `pillX` is the ONE source of truth for the
    // pill's horizontal center, and three forces feed it:
    //   • the cursor (lagged, magnetic follow between columns — task #3),
    //   • a column lock when the cursor lands close enough (snaps + haptic),
    //   • focus claimed by scrolling/tapping a wheel (springs to that column).
    // All of them just animate `pillX`, so they compose instead of fighting.

    /// Live horizontal center of the pill, in wheel-group local coords. `nil`
    /// until the first layout pass seeds it from the initially-focused column.
    @State private var pillX: CGFloat? = nil
    /// Live cursor X inside the wheel group (from `.onContinuousHover`), or `nil`
    /// when the cursor is outside the wheels. Drives the magnetic follow.
    @State private var mouseX: CGFloat? = nil
    /// Last column width seen by layout — cached so the hover/snap math (which
    /// runs outside the GeometryReader) can reuse it.
    @State private var lastColW: CGFloat = 0

    // Scroll-driven deformation state. While a wheel is scrolled the pill
    // stretches along the drag (vertical) axis, anchored under the cursor; it
    // springs back to rest when scrolling stops. These two feed a GeometryEffect
    // that LAYERS on top of the focus stretch-pulse keyframes (see `pill`).
    /// Signed vertical stretch: +down / -up, 0 at rest.
    @State private var scrollStretch: CGFloat = 0
    /// Normalized horizontal origin (0…1 across the pill) of the stretch — comes
    /// from where the cursor sits relative to the pill center, so dragging near
    /// an edge tilts/anchors the deform there instead of symmetric-center.
    @State private var scrollAnchorX: CGFloat = 0.5
    /// Generation token so a fresh scroll tick cancels the previous spring-back.
    @State private var scrollSettleToken: Int = 0

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

    // MARK: Mouse-follow / magnet tuning (task #3 — the "glue then sudden pull")
    //
    // The calendar carousel's signature is: a resisted (0.25 "glue") follow, a
    // velocity/offset threshold, then a spring snap. We mirror that feel for the
    // pill: between columns the pill follows the cursor at a fraction of the
    // distance (looseFollow = the 0.25 analogue, the stretchy lag); once the
    // cursor is within `snapRadius` of a column center the pill is yanked fully
    // onto it (magnetic lock) and focus + a haptic fire.
    /// Fraction of the cursor→center distance the pill closes when loosely
    /// following (lower = stickier/laggier, the calendar's 0.25 resistance).
    fileprivate static let looseFollow: CGFloat = 0.32
    /// Within this distance (pts) of a column center the pill locks onto it.
    fileprivate static let snapRadius: CGFloat = 18

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
            // Cache the live column width and seed the pill's resting position
            // on the focused column the first time we know the geometry.
            .onAppear {
                lastColW = colW
                if pillX == nil { pillX = columnCenterX(colW: colW) }
            }
            .onChange(of: colW) { _, new in
                lastColW = new
                // Keep the pill glued to its column if the widget is resized
                // while the cursor isn't actively driving it.
                if mouseX == nil {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        pillX = columnCenterX(colW: new)
                    }
                }
            }
            // Focus claimed elsewhere (scroll/tap) while the cursor isn't
            // actively steering the pill → spring the pill to that column. When
            // the cursor IS driving, the magnetic follow already owns pillX.
            .onChange(of: focusedWheel) { _, _ in
                if mouseX == nil {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.7)) {
                        pillX = columnCenterX(colW: colW)
                    }
                }
            }
            // Continuous cursor X (local coords) is the cleanest live mouse
            // stream on macOS — drives the magnetic follow in task #3.
            .onContinuousHover(coordinateSpace: .local) { phase in
                switch phase {
                case .active(let p): updateMouseFollow(p.x, colW: colW)
                case .ended:         endMouseFollow(colW: colW)
                }
            }
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
    // Two independent deformations ride on this pill and are deliberately kept on
    // SEPARATE layers so they never fight (see `pill`):
    //   • the focus stretch-PULSE — a keyframe scale fired on column lock
    //     (`focusedWheel`), symmetric about the center;
    //   • the scroll DEFORMATION — a cursor-anchored vertical stretch driven by
    //     a GeometryEffect that springs back when scrolling stops.
    // The crisp number is NOT embedded here — it rides BEHIND the lens, so the
    // bubble can travel and stretch without dragging the digit.
    @ViewBuilder
    private func focusIndicator(colW: CGFloat) -> some View {
        let pillW = pillWidth(colW: colW)
        let pillH = pillHeight
        // Continuous center; falls back to the focused column until the first
        // layout pass seeds `pillX`.
        let centerX = pillX ?? columnCenterX(colW: colW)

        pill(width: pillW, height: pillH)
            // Position from the leading edge, then nudge by half the group so
            // offset 0 == group center; centerX is already absolute-from-left.
            .frame(width: pillW, height: pillH)
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(x: centerX - pillW / 2)
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
        // LAYER 1 — focus stretch-PULSE: a symmetric (center-anchored) scale
        // pop fired whenever the pill locks onto a new column. Unchanged from
        // the original; it owns the "expand mid-travel, settle when parked"
        // signature and is driven purely by the discrete `focusedWheel` trigger.
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
        // LAYER 2 — scroll DEFORMATION: a cursor-anchored vertical stretch that
        // tracks the wheel being scrolled and springs back to rest. It composes
        // on top of LAYER 1 because it's a DIFFERENT transform (anchored
        // shear/stretch vs. a symmetric center scale), so the two never cancel
        // or double-count each other — they multiply cleanly as transforms.
        // `scrollStretch` is animated EXPLICITLY at its mutation sites in
        // `deform(direction:)` (interactiveSpring on each tick, a bouncy settle
        // on release), so no implicit `.animation(value:)` here — that would
        // double-drive the same property and fight the explicit transactions.
        .modifier(ScrollDeformEffect(stretchY: scrollStretch, anchorX: scrollAnchorX))
    }

    private var wheelsRow: some View {
        HStack(spacing: 0) {
            NumberWheel(value: $hours,   range: 0...23, suffix: "h",
                        index: 0, focusedWheel: $focusedWheel,
                        onScrollTick: { deform(direction: $0) })
            separator
            NumberWheel(value: $minutes, range: 0...59, suffix: "m",
                        index: 1, focusedWheel: $focusedWheel,
                        onScrollTick: { deform(direction: $0) })
            separator
            NumberWheel(value: $seconds, range: 0...59, suffix: "s",
                        index: 2, focusedWheel: $focusedWheel,
                        onScrollTick: { deform(direction: $0) })
        }
    }

    private var separator: some View {
        Text(":")
            .font(.system(size: 18, weight: .semibold).monospacedDigit())
            .foregroundStyle(Color.white.opacity(0.32))
            .frame(width: Self.wheelGap)
    }

    // MARK: - Mouse-follow + magnetic snap (task #3)

    /// Driven on every `.onContinuousHover` sample. The pill follows the cursor
    /// at a fraction of the gap (the calendar's resisted "glue"), then is yanked
    /// fully onto a column once the cursor is close enough — at which point focus
    /// locks and a haptic fires. The blend is nonlinear (a closeness ease), so it
    /// reads as "loose drift, then a sudden magnetic pull".
    private func updateMouseFollow(_ x: CGFloat, colW: CGFloat) {
        mouseX = x
        lastColW = colW

        // Nearest column center to the cursor.
        let step = colW + Self.wheelGap
        let nearest = max(0, min(2, Int((x - colW / 2 + step / 2) / step)))
        let center = columnCenterX(colW: colW)
        let centerOfNearest = colW / 2 + CGFloat(nearest) * step
        let dist = abs(x - centerOfNearest)

        // closeness: 0 far away → 1 right on the center, eased so the pull ramps
        // up sharply near the column (the "sudden" part of the signature).
        let snapZone = colW / 2
        let raw = max(0, 1 - dist / snapZone)
        let closeness = raw * raw                       // ease-in: gentle then steep

        // Loose follow target: the cursor pulled a fraction of the way toward
        // the pill's current rest, blended toward the magnet as we close in.
        let resting = pillX ?? center
        let looseTarget = resting + (x - resting) * Self.looseFollow
        let target = looseTarget + (centerOfNearest - looseTarget) * closeness

        // Inside the snap radius: hard-lock to the column, claim focus + haptic.
        if dist <= Self.snapRadius {
            if focusedWheel != nearest {
                TimerHaptics.shared.lock()
                withAnimation(.spring(response: 0.34, dampingFraction: 0.7)) {
                    focusedWheel = nearest
                }
            }
            withAnimation(.spring(response: 0.34, dampingFraction: 0.72)) {
                pillX = centerOfNearest
            }
        } else {
            // Stretchy, laggy follow between columns.
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                pillX = target
            }
        }
    }

    /// Cursor left the wheels — settle the pill back onto the locked column.
    private func endMouseFollow(colW: CGFloat) {
        mouseX = nil
        withAnimation(.spring(response: 0.4, dampingFraction: 0.74)) {
            pillX = columnCenterX(colW: colW)
        }
    }

    // MARK: - Scroll-driven deformation (task #1)

    /// Called by a wheel on each integer tick while it is scrolled. We pulse the
    /// pill's vertical stretch in the scroll direction (anchored under the
    /// cursor), then debounce a spring-back to rest once the ticks stop. Ticks
    /// arrive fast enough while scrolling that this reads as a continuous,
    /// liquid stretch that settles with overshoot when the wheel stops.
    private func deform(direction: Int) {
        // Anchor the stretch under the cursor: convert mouseX into a 0…1 position
        // across the pill so dragging near an edge tilts the deform there.
        if let mx = mouseX, lastColW > 0, let px = pillX {
            let pw = pillWidth(colW: lastColW)
            let local = (mx - (px - pw / 2)) / max(pw, 1)
            scrollAnchorX = min(1, max(0, local))
        } else {
            scrollAnchorX = 0.5
        }

        // Peak stretch in the drag direction (clamped). interactiveSpring on the
        // pill (see `pill`) carries the value smoothly between rapid ticks.
        withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.55)) {
            scrollStretch = CGFloat(direction > 0 ? 1 : -1) * 0.5
        }

        // Debounce the spring-back: the latest tick wins, so the pill only
        // relaxes once scrolling actually stops.
        scrollSettleToken += 1
        let token = scrollSettleToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
            guard token == scrollSettleToken else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                scrollStretch = 0          // bouncy settle (liquid overshoot)
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

// MARK: - Pill stretch (keyframe state)

/// Drives the focus pill's stretch/squash pulse as it slides between wheels.
private struct PillStretch {
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
}

// MARK: - Scroll deformation (cursor-anchored stretch)

/// A `GeometryEffect` that stretches the pill along the vertical (drag) axis
/// while a wheel is scrolled, with the deformation ORIGINATING at the cursor's
/// horizontal position rather than the symmetric center. `anchorX` (0…1 across
/// the pill) offsets where the stretch is pinned, and a small lateral shear
/// proportional to the cursor's offset-from-center tilts the bubble toward the
/// drag — so scrolling near an edge skews the glass there, like dragging real
/// liquid. Kept as a separate effect so it composes with (instead of fighting)
/// the symmetric focus stretch-pulse keyframes.
private struct ScrollDeformEffect: GeometryEffect {
    /// Signed vertical stretch: +down / -up, 0 at rest.
    var stretchY: CGFloat
    /// Normalized horizontal origin of the deformation (0 = leading … 1 = trailing).
    var anchorX: CGFloat

    // Only the magnitude needs to animate; anchorX rides along untouched.
    var animatableData: CGFloat {
        get { stretchY }
        set { stretchY = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let mag = stretchY
        guard mag != 0 else { return ProjectionTransform(.identity) }

        // Stretch along the drag axis, gently thinning the cross-axis so volume
        // reads as conserved (squash-and-stretch).
        let sy = 1 + abs(mag) * 0.5
        let sx = 1 - abs(mag) * 0.16
        // Lateral lean toward the cursor's side, scaled by how far the anchor is
        // from center and the drag magnitude.
        let lean = (anchorX - 0.5) * mag * 0.5 * size.width

        // Anchor the scale at the cursor's X (and the pill's vertical center) so
        // the deformation grows OUT of where the cursor sits.
        let ax = anchorX * size.width
        let ay = size.height / 2

        var t = CGAffineTransform.identity
        t = t.translatedBy(x: ax + lean, y: ay)
        t = t.scaledBy(x: sx, y: sy)
        t = t.translatedBy(x: -ax, y: -ay)
        return ProjectionTransform(t)
    }
}

// MARK: - NumberWheel

private struct NumberWheel: View {
    @Binding var value: Int
    var range: ClosedRange<Int>
    var suffix: String
    var index: Int
    @Binding var focusedWheel: Int
    /// Notifies the parent on each integer scroll tick with the drag direction
    /// (+1 = value increasing/scroll down, -1 = up) so it can deform the pill.
    var onScrollTick: (Int) -> Void

    private var rowHeight: CGFloat   { TimerCreatorView.rowHeight }
    private var wheelHeight: CGFloat { TimerCreatorView.wheelHeight }

    /// This wheel's haptic unit, derived from its column index (0=h,1=m,2=s).
    /// Each unit gets a distinct tick pattern from `TimerHaptics`.
    private var unit: TimerWheelUnit {
        switch index {
        case 0:  return .hours
        case 1:  return .minutes
        default: return .seconds
        }
    }

    @State private var scrollPosition: Int?

    init(value: Binding<Int>, range: ClosedRange<Int>, suffix: String,
         index: Int, focusedWheel: Binding<Int>,
         onScrollTick: @escaping (Int) -> Void) {
        self._value = value
        self.range = range
        self.suffix = suffix
        self.index = index
        self._focusedWheel = focusedWheel
        self.onScrollTick = onScrollTick
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
                                TimerHaptics.shared.tick(unit)
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
        // NOTE: hover-to-focus is no longer claimed here. The PARENT owns the
        // live cursor stream (`.onContinuousHover` on the wheel group) and runs
        // the magnetic follow/snap — letting this wheel grab focus on plain
        // `.onHover` would pre-empt that "drift then sudden pull" and swallow the
        // lock haptic. Scrolling/tapping still claims focus via `focusWheel()`.
        .onAppear { scrollPosition = value }
        .onChange(of: scrollPosition) { old, new in
            guard let new else { return }
            if new != value {
                // Direction of this tick drives the pill's scroll deformation.
                let direction = (old.map { new > $0 } ?? (new > value)) ? 1 : -1
                value = new
                TimerHaptics.shared.tick(unit)
                onScrollTick(direction)
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
