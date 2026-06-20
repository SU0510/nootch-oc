//
//  ProgressiveBlurView.swift
//  NotchNook
//
//  A reusable PROGRESSIVE (variable / gradient) blur for macOS, built on the same
//  private CoreAnimation primitive SwiftUI's `.glassEffect()` and our
//  `NativeGlassPill` already use: a `CABackdropLayer` (which samples the
//  already-composited window content BEHIND it, on the GPU, off the main thread)
//  carrying a `CAFilter(type: "gaussianBlur")`. The blur is made *progressive* by
//  feeding the filter an `inputMaskImage` — a vertical alpha ramp. Where the mask
//  is opaque the backdrop is fully blurred; where it's clear the backdrop passes
//  through untouched. The result: content dissolves into frost toward one edge and
//  stays crisp toward the other, exactly like an iOS picker's top "header" fade.
//
//  This is the classic `VariableBlurView` recipe (AlexStrNik) and is deliberately
//  LIGHTER than `NativeGlassPill` — it needs only `CABackdropLayer` + `CAFilter`,
//  no SDF/highlight machinery. It samples FOREGROUND sibling content drawn beneath
//  it in the same window (the wheel digits), not the desktop wallpaper, so placing
//  it as a non-interactive overlay over a view region blurs *that view's pixels*.
//
//  Private-API use is fine here (NotchNook is not shipped on the Mac App Store) and
//  is runtime-gated exactly like `NativeGlassPill`: every private class is resolved
//  via `NSClassFromString`, and if any is missing `isAvailable` is false so the
//  call site can fall back gracefully (e.g. to a plain alpha fade). Nothing
//  force-unwraps a private symbol.
//

import AppKit
import SwiftUI

// MARK: - Private class resolution (one-time, defensive)

/// Resolved private CoreAnimation classes needed for the variable blur. If either
/// is nil the effect is unavailable and callers must fall back (see
/// `ProgressiveBlur.isAvailable`).
private enum PrivateBlurClasses {
    static let backdrop = NSClassFromString("CABackdropLayer") as? CALayer.Type
    static let filter = NSClassFromString("CAFilter") as? NSObject.Type

    static let available: Bool = backdrop != nil && filter != nil
}

// MARK: - Geometry

/// Which edge the blur is STRONGEST at. The ramp falls from full blur at this edge
/// to zero blur at `rampEnd` (a fraction of the view's length along the axis).
enum ProgressiveBlurEdge {
    case top, bottom, leading, trailing
}

// MARK: - NSView

/// Hosts a single `CABackdropLayer` + `gaussianBlur` `CAFilter`, masked by a
/// vertical (or horizontal) alpha ramp so the blur is progressive. Rebuilds the
/// mask image only when its size changes. Decorative + non-interactive: it lets
/// every event fall through to the views beneath it (e.g. the scroll wheels).
final class ProgressiveBlurNSView: NSView {

    /// Peak blur radius (points) at the strong edge.
    var maxRadius: CGFloat = 12 { didSet { if oldValue != maxRadius { needsLayout = true } } }
    /// Edge the blur is strongest at.
    var edge: ProgressiveBlurEdge = .top { didSet { if oldValue != edge { needsLayout = true } } }
    /// Fraction of the view's length (0…1, measured FROM the strong edge) over
    /// which the blur ramps from full → zero. Past this the backdrop passes
    /// through crisp, so the focused/center content stays sharp.
    var rampLength: CGFloat = 0.5 { didSet { if oldValue != rampLength { needsLayout = true } } }
    /// Curve sharpness of the ramp (>1 keeps blur concentrated near the edge).
    var curveExponent: CGFloat = 1.6 { didSet { if oldValue != curveExponent { needsLayout = true } } }

    private var backdropLayer: CALayer?
    private var blurFilter: NSObject?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
        buildBackdrop()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Fully transparent to hit-testing so scroll/tap reach the wheels beneath.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    // NOTE: deliberately NOT flipped. `isFlipped = true` flips the backing layer's
    // contents, which flipped the variable-blur mask image — putting the blurred
    // band on the BOTTOM instead of the top. Default (non-flipped) keeps the mask's
    // top row at the view's top edge.

    private func buildBackdrop() {
        guard let backdropClass = PrivateBlurClasses.backdrop,
              let filterClass = PrivateBlurClasses.filter,
              let host = layer else { return }

        let backdrop = backdropClass.init()
        backdrop.anchorPoint = .zero
        // Sample the composited window content on the WindowServer (matches
        // NativeGlassPill so it picks up sibling SwiftUI content beneath us).
        let bd = backdrop as NSObject
        bd.setValue(true, forKey: "tracksLuma")
        bd.setValue(true, forKey: "allowsFilteredLuma")
        bd.setValue(true, forKey: "windowServerAware")
        bd.setValue(1, forKey: "scale")

        // `variableBlur` (NOT `gaussianBlur`): the gaussian filter ignores
        // `inputMaskImage` and blurs UNIFORMLY — which frosts the whole region and
        // erases the digits. Only `variableBlur` reads the per-pixel ramp, so the
        // blur is strong at the edge and zero (crisp passthrough) past the ramp.
        guard let filter = filterClass
            .perform(#selector(CAFilter.init(type:)), with: "variableBlur")?
            .takeUnretainedValue() as? NSObject else { return }
        filter.setValue(maxRadius, forKey: "inputRadius")
        filter.setValue(true, forKey: "inputNormalizeEdges")
        backdrop.setValue([filter], forKey: "filters")

        host.addSublayer(backdrop)
        backdropLayer = backdrop
        blurFilter = filter
    }

    override func layout() {
        super.layout()
        guard let backdrop = backdropLayer, let filter = blurFilter else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        backdrop.frame = bounds
        filter.setValue(maxRadius, forKey: "inputRadius")
        if let mask = makeRampMaskImage(size: bounds.size) {
            filter.setValue(mask, forKey: "inputMaskImage")
        }
        CATransaction.commit()
    }

    /// Builds the ALPHA ramp that drives the variable blur.
    ///
    /// CRITICAL: `variableBlur` reads this mask's **alpha channel** per pixel —
    /// alpha 1 = full blur (`inputRadius`), alpha 0 = crisp passthrough. It does
    /// NOT read luminance. A mask with no alpha channel (constant alpha 1) blurs
    /// EVERYTHING uniformly — which is exactly the "all blurry" failure. So the
    /// strong edge gets alpha ≈ 1 and the far side alpha 0, in a real RGBA bitmap.
    private func makeRampMaskImage(size: CGSize) -> CGImage? {
        let w = max(1, Int(size.width.rounded()))
        let h = max(1, Int(size.height.rounded()))
        let vertical = (edge == .top || edge == .bottom)
        let count = max(1, vertical ? h : w)

        // Per-line alpha (0…255): 1 at the strong edge, easing to 0 past rampLength.
        var alpha = [UInt8](repeating: 0, count: count)
        let ramp = max(0.0001, min(1, rampLength))
        for i in 0..<count {
            // Normalized distance from the STRONG edge (0 at edge → 1 far side).
            let pos = Double(i) / Double(max(1, count - 1))
            let fromEdge: Double
            switch edge {
            case .top, .leading:      fromEdge = pos
            case .bottom, .trailing:  fromEdge = 1 - pos
            }
            // blurAmount: 1 at the edge, ramping to 0 once we pass `rampLength`.
            let blurAmount = max(0, 1 - fromEdge / Double(ramp))
            let eased = pow(blurAmount, Double(curveExponent))
            alpha[i] = UInt8((eased * 255).rounded())
        }

        // Premultiplied RGBA: keep RGB at 0 (black) and vary only A. The filter
        // samples A; black premultiplied by varying alpha stays valid.
        let bytesPerRow = w * 4
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * h)
        for y in 0..<h {
            for x in 0..<w {
                let a = vertical ? alpha[min(y, count - 1)] : alpha[min(x, count - 1)]
                let o = y * bytesPerRow + x * 4
                // R,G,B = 0; A = ramp. (Premultiplied: RGB already ≤ A.)
                pixels[o + 3] = a
            }
        }

        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: &pixels, width: w, height: h, bitsPerComponent: 8,
            bytesPerRow: bytesPerRow, space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        return ctx.makeImage()
    }
}

// MARK: - SwiftUI wrapper

/// A progressive (variable) blur of the content composited BEHIND it, ramping from
/// full blur at `edge` to crisp by `rampLength`. Place it as a non-interactive
/// overlay over the region you want to frost (e.g. the top of a scroll wheel). The
/// center/focused content stays sharp because the ramp reaches zero before it.
///
/// Gate the call site on `ProgressiveBlur.isAvailable` and fall back to an alpha
/// fade when the private backdrop primitive is missing.
struct ProgressiveBlur: NSViewRepresentable {
    var maxRadius: CGFloat = 12
    var edge: ProgressiveBlurEdge = .top
    var rampLength: CGFloat = 0.5
    var curveExponent: CGFloat = 1.6

    /// Whether the private `CABackdropLayer` + `CAFilter` primitive is usable.
    static var isAvailable: Bool { PrivateBlurClasses.available }

    func makeNSView(context: Context) -> ProgressiveBlurNSView {
        let v = ProgressiveBlurNSView()
        v.translatesAutoresizingMaskIntoConstraints = true
        v.maxRadius = maxRadius
        v.edge = edge
        v.rampLength = rampLength
        v.curveExponent = curveExponent
        return v
    }

    func updateNSView(_ v: ProgressiveBlurNSView, context: Context) {
        v.maxRadius = maxRadius
        v.edge = edge
        v.rampLength = rampLength
        v.curveExponent = curveExponent
    }
}
