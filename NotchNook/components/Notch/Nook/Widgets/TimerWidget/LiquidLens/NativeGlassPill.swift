//
//  NativeGlassPill.swift
//  NotchNook
//
//  macOS 26+ native Liquid Glass pill, built from the private CoreAnimation stack
//  SwiftUI's own `.glassEffect()` uses: CABackdropLayer + a `glassBackground`
//  CAFilter + CASDFLayer/CASDFElementLayer. Unlike the Metal `LiquidLensView`
//  fallback (which re-rasterizes the view tree every frame on the main thread via
//  `CALayer.render(in:)`), this runs entirely in the WindowServer: it samples the
//  already-composited framebuffer behind the pill on the GPU, off our thread. That
//  makes it both far cheaper AND world-anchored by construction — the backdrop is
//  sampled at the pill's real composited screen position, so the "background drifts
//  with the pill" problem of the capture-based lens cannot occur here.
//
//  Layer hierarchy (mirrors AlexStrNik/ShatteredGlass; bridging decls live in
//  NativeGlass-Bridging-Header.h):
//
//    SwiftUI.SDFLayer                         (optional wrapper)
//      ├── CABackdropLayer  "@0"  filters=[glassBackground]
//      │     └── CASDFLayer  "@0"  effect=CASDFOutputEffect
//      │           └── CALayer (container)
//      │                 └── CASDFElementLayer   ← the pill shape (capsule)
//      ├── CASDFLayer  "@1"  effect=CASDFGlassHighlightEffect(+45°)  filters=[vibrantColorMatrix]
//      │     └── SDFPortalLayer → sources the CASDFElementLayer
//      └── CASDFLayer  "@2"  effect=CASDFGlassHighlightEffect(-135°) filters=[vibrantColorMatrix]
//            └── SDFPortalLayer → sources the CASDFElementLayer
//
//  All private classes are resolved via `NSClassFromString`; if ANY is missing
//  (e.g. a future OS renames them) `isAvailable` is false and the SwiftUI call
//  site falls back to the Metal lens. Nothing here force-unwraps a private symbol.
//

import AppKit
import SwiftUI

// MARK: - Private class resolution (one-time, defensive)

/// Resolved private CoreAnimation classes. If any is nil the native path is
/// unavailable and callers must fall back (see `NativeGlassPill.isAvailable`).
private enum PrivateGlassClasses {
    static let backdrop = NSClassFromString("CABackdropLayer") as? CALayer.Type
    static let sdf = NSClassFromString("CASDFLayer") as? CALayer.Type
    static let sdfElement = NSClassFromString("CASDFElementLayer") as? CALayer.Type
    static let outputEffect = NSClassFromString("CASDFOutputEffect") as? NSObject.Type
    static let glassHighlightEffect = NSClassFromString("CASDFGlassHighlightEffect") as? NSObject.Type
    static let filter = NSClassFromString("CAFilter") as? NSObject.Type
    // Mangled SwiftUI symbol — a CAPortalLayer variant that can source a
    // CASDFElementLayer from inside the CABackdropLayer subtree.
    static let portal = NSClassFromString(
        "_TtC7SwiftUIP33_05C1F5BE6EE7940FED05100EA822F7B314SDFPortalLayer"
    ) as? CALayer.Type
    // Optional wrapper/delegate — the effect works without them, so they are not
    // required for `available`.
    static let suiSDFLayer = NSClassFromString("SwiftUI.SDFLayer") as? CALayer.Type
    static let suiSDFLayerDelegate: AnyClass? = NSClassFromString("_SwiftUISDFLayerDelegate")

    /// True only if every layer/effect/filter class needed to build the stack
    /// resolved. Optional wrapper/delegate are excluded on purpose.
    static let available: Bool =
        backdrop != nil && sdf != nil && sdfElement != nil &&
        outputEffect != nil && glassHighlightEffect != nil &&
        filter != nil && portal != nil
}

// MARK: - NSView

/// Hosts the native glass layer stack. Rebuilds the tree whenever its size
/// changes (the SDF shape is size-dependent). Decorative + non-interactive.
final class NativeGlassPillView: NSView {

    /// Corner radius of the capsule. `< 0` means "fully rounded" (height / 2),
    /// matching `LiquidLensPill`'s capsule.
    var cornerRadius: CGFloat = -1 {
        didSet { if oldValue != cornerRadius { needsLayout = true } }
    }

    /// Strong reference to the element layer so the highlight portals can keep
    /// sourcing it across rebuilds.
    private weak var elementLayer: CALayer?

    /// Size the current layer tree was built for; avoids rebuilding every layout
    /// pass (AppKit calls `layout()` often; the slide is a transform, not a
    /// resize, so the size is usually stable).
    private var builtSize: CGSize = .zero
    private var builtRadius: CGFloat = .nan

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        let size = bounds.size
        let radius = effectiveRadius(for: size)
        guard size.width > 0, size.height > 0 else { return }
        // Rebuild only when geometry actually changed.
        if size == builtSize, radius == builtRadius, layer?.sublayers?.isEmpty == false {
            return
        }
        builtSize = size
        builtRadius = radius
        rebuildLayers(size: size, radius: radius)
    }

    private func effectiveRadius(for size: CGSize) -> CGFloat {
        cornerRadius < 0 ? size.height / 2 : min(cornerRadius, size.height / 2)
    }

    // MARK: Layer assembly

    private func rebuildLayers(size: CGSize, radius: CGFloat) {
        guard PrivateGlassClasses.available,
              let root = makeGlassLayer(size: size, radius: radius) else { return }
        root.frame = CGRect(origin: .zero, size: size)
        self.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        self.layer?.addSublayer(root)
    }

    /// Builds the full stack and returns its root layer (the SwiftUI.SDFLayer
    /// wrapper when available, otherwise a plain CALayer container).
    private func makeGlassLayer(size: CGSize, radius: CGFloat) -> CALayer? {
        guard let elementContainer = makeSDFElementLayer(size: size, radius: radius),
              let element = elementContainer.sublayers?.first,
              let backdrop = makeBackdropLayer(size: size, sdfElementLayer: elementContainer)
        else { return nil }

        let rootLayer: CALayer
        if let suiClass = PrivateGlassClasses.suiSDFLayer {
            let sui = suiClass.init()
            sui.bounds = CGRect(origin: .zero, size: size)
            sui.setValue(false, forKey: "allowsGroupOpacity")
            rootLayer = sui
        } else {
            rootLayer = CALayer()
        }

        // Mirrors ShatteredGlass: the backdrop's delegate is the SwiftUI.SDFLayer
        // wrapper itself (when present). Harmless when the wrapper is a plain
        // CALayer (it just isn't a CALayerDelegate, so this stays nil).
        backdrop.delegate = rootLayer as? CALayerDelegate
        rootLayer.addSublayer(backdrop)

        // Two edge-highlight layers at opposite angles (Apple's values).
        if let glass1 = makeGlassHighlightLayer(size: size, name: "@1",
                                                 element: element, angle: 0.78539816339744828) {
            rootLayer.addSublayer(glass1)
        }
        if let glass2 = makeGlassHighlightLayer(size: size, name: "@2",
                                                 element: element, angle: -2.3561944901923448) {
            rootLayer.addSublayer(glass2)
        }

        elementLayer = element
        return rootLayer
    }

    /// CALayer container holding the CASDFElementLayer that defines the pill shape.
    private func makeSDFElementLayer(size: CGSize, radius: CGFloat) -> CALayer? {
        guard let elementClass = PrivateGlassClasses.sdfElement else { return nil }

        let container = CALayer()
        container.bounds = CGRect(origin: .zero, size: size)
        container.anchorPoint = .zero

        let element = elementClass.init()
        element.cornerRadius = radius                       // capsule when radius == h/2
        element.setValue(0.5, forKey: "gradientOvalization")
        element.anchorPoint = .zero
        element.bounds = CGRect(origin: .zero, size: size)
        (element as NSObject).setValue("bounds", forKey: "mode")
        (element as NSObject).setValue("union", forKey: "operation")

        if let delegateClass = PrivateGlassClasses.suiSDFLayerDelegate {
            element.perform(#selector(Port.setDelegate(_:)), with: delegateClass)
        }

        container.addSublayer(element)
        return container
    }

    /// CABackdropLayer with the `glassBackground` filter — the refraction itself.
    private func makeBackdropLayer(size: CGSize, sdfElementLayer: CALayer) -> CALayer? {
        guard let backdropClass = PrivateGlassClasses.backdrop,
              let sdfClass = PrivateGlassClasses.sdf,
              let outputEffectClass = PrivateGlassClasses.outputEffect,
              let filterClass = PrivateGlassClasses.filter else { return nil }

        let backdrop = backdropClass.init()
        backdrop.bounds = CGRect(origin: .zero, size: size)
        // Anchor at top-left like the sibling SDF layers; without this the
        // backdrop defaults to anchorPoint (0.5,0.5) at position (0,0) and renders
        // shifted up-and-left by half its size (the visible misalignment).
        backdrop.anchorPoint = .zero
        backdrop.name = "@0"
        backdrop.setValue(false, forKey: "allowsGroupOpacity")
        let bd = backdrop as NSObject
        bd.setValue(true, forKey: "tracksLuma")
        bd.setValue(true, forKey: "allowsFilteredLuma")
        bd.setValue(true, forKey: "windowServerAware")
        bd.setValue(1, forKey: "scale")

        let sdf = sdfClass.init()
        sdf.anchorPoint = .zero
        sdf.bounds = CGRect(origin: .zero, size: size)
        sdf.setValue(8.0, forKey: "smoothness")

        let output = outputEffectClass.init()
        output.setValue(-1000.0, forKey: "minimum")
        output.setValue(1.0, forKey: "maximum")
        sdf.setValue(output, forKey: "effect")

        sdf.name = "@0"
        sdf.sublayers = [sdfElementLayer]
        backdrop.sublayers = [sdf]

        let filter = filterClass.perform(#selector(CAFilter.init(type:)), with: "glassBackground")?
            .takeUnretainedValue() as? NSObject
        guard let filter else { return nil }
        applyGlassBackgroundDefaults(to: filter)
        backdrop.setValue([filter], forKey: "filters")

        return backdrop
    }

    /// Apple's reverse-engineered `glassBackground` default key set (verbatim from
    /// ShatteredGlass). Tunable later; this is the authentic iOS-26 bar look.
    private func applyGlassBackgroundDefaults(to filter: NSObject) {
        // Name of the source CASDFLayer — REQUIRED for the filter to find its SDF.
        filter.setValue("@0", forKey: "inputSourceSublayerName")
        filter.setValue(NSSize(width: 0, height: 8), forKey: "inputShadowOffset")
        filter.setValue(31.25, forKey: "inputShadowAmount")
        filter.setValue(20, forKey: "inputShadowHeight")
        filter.setValue(0, forKey: "inputShadowDistanceOffset")
        filter.setValue(40, forKey: "inputShadowBlurRadius")
        filter.setValue(24, forKey: "inputShadowRadius")
        filter.setValue(0, forKey: "inputShadowColorMatrixBlack")
        filter.setValue(0.5, forKey: "inputShadowColorMatrixWhite")
        filter.setValue(1, forKey: "inputShadowColorMatrixSaturation")
        filter.setValue(0.25, forKey: "inputShadowColorMatrixFillColor")
        filter.setValue(0.4, forKey: "inputShadowOpacity")
        filter.setValue(0.3, forKey: "inputShadowVibrancyContribution")
        filter.setValue(0, forKey: "inputBlurRadius")
        filter.setValue(0, forKey: "inputBlurDistance0")
        filter.setValue(0, forKey: "inputBlurDistance1")
        filter.setValue(0, forKey: "inputBlurDistance2")
        filter.setValue(0, forKey: "inputBlurDistance3")
        filter.setValue(0, forKey: "inputBlurDistance4")
        filter.setValue(0, forKey: "inputBlurOpacity0")
        filter.setValue(0, forKey: "inputBlurOpacity1")
        filter.setValue(0, forKey: "inputBlurOpacity2")
        filter.setValue(0, forKey: "inputBlurOpacity3")
        filter.setValue(0, forKey: "inputBlurOpacity4")
        filter.setValue(-40, forKey: "inputInnerRefractionAmount")
        filter.setValue(10, forKey: "inputInnerRefractionHeight")
        filter.setValue(10, forKey: "inputOuterRefractionAmount")
        filter.setValue(6.25, forKey: "inputOuterRefractionHeight")
        filter.setValue(-2, forKey: "inputRefractionDistance0")
        filter.setValue(-1, forKey: "inputRefractionDistance1")
        filter.setValue(1, forKey: "inputRefractionOpacity")
        filter.setValue(1, forKey: "inputFaceOpacity")
        filter.setValue(0, forKey: "inputFaceColorMatrixBlack")
        filter.setValue(1, forKey: "inputFaceColorMatrixWhite")
        filter.setValue(1, forKey: "inputFaceColorMatrixSaturation")
        // Tints the glass.
        filter.setValue(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.01),
                        forKey: "inputFaceColorMatrixFillColor")
        filter.setValue(17.5, forKey: "inputBleedAmount")
        filter.setValue(17.5, forKey: "inputBleedHeight")
        filter.setValue(24, forKey: "inputBleedBlurRadius")
        filter.setValue(1, forKey: "inputBleedOpacity")
        filter.setValue(1, forKey: "inputBleedDistance0")
        filter.setValue(0, forKey: "inputBleedDistance1")
        filter.setValue(0, forKey: "inputBleedColorMatrixBlack")
        filter.setValue(1, forKey: "inputBleedColorMatrixWhite")
        filter.setValue(1, forKey: "inputBleedColorMatrixSaturation")
        filter.setValue(nil, forKey: "inputBleedColorMatrixFillColor")
        filter.setValue(0, forKey: "inputBleedDarkenBlend")
        filter.setValue(1, forKey: "inputSDRHoldingToneEnabled")
        filter.setValue(9999, forKey: "inputMaxHeadroom")
        filter.setValue(-1, forKey: "inputSDRGradientDistance0")
        filter.setValue(-0.5, forKey: "inputSDRGradientDistance1")
        filter.setValue(0.12, forKey: "inputSDRShadowOpacity")
    }

    /// One directional edge-highlight layer (a CASDFLayer with a glass-highlight
    /// effect + vibrant color matrix, sourcing the shared element via a portal).
    private func makeGlassHighlightLayer(size: CGSize, name: String,
                                         element: CALayer, angle: Double) -> CALayer? {
        guard let sdfClass = PrivateGlassClasses.sdf,
              let highlightClass = PrivateGlassClasses.glassHighlightEffect,
              let filterClass = PrivateGlassClasses.filter,
              let portalClass = PrivateGlassClasses.portal else { return nil }

        let sdf = sdfClass.init()
        sdf.bounds = CGRect(origin: .init(x: -size.width / 2, y: -size.height / 2), size: size)
        sdf.anchorPoint = .zero
        sdf.name = name
        sdf.setValue(size.height / 4, forKey: "smoothness")

        let highlight = highlightClass.init()
        highlight.setValue(0.6, forKey: "amount")
        highlight.setValue(angle, forKey: "angle")
        highlight.setValue(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1), forKey: "color")
        highlight.setValue(1.7, forKey: "curvature")
        highlight.setValue(1.0, forKey: "height")
        highlight.setValue(1.59, forKey: "spread")

        let vibrant = filterClass.perform(#selector(CAFilter.init(type:)), with: "vibrantColorMatrix")?
            .takeUnretainedValue() as? NSObject
        if let vibrant {
            let matrix = CAColorMatrix(
                m11: 2.6705, m12: -1.1087999, m13: -0.1117, m14: 0.0, m15: 0.049999997,
                m21: -0.3295, m22: 1.8914, m23: -0.111899994, m24: 0.0, m25: 0.049999997,
                m31: -0.3297, m32: -1.1084, m33: 2.8881, m34: 0.0, m35: 0.049999997,
                m41: 0.0, m42: 0.0, m43: 0.0, m44: 1.0, m45: 0.0
            )
            // `+valueWithCAColorMatrix:` (bridging header) is imported by Swift
            // as this initializer.
            let value = NSValue(caColorMatrix: matrix)
            vibrant.setValue(value, forKey: "inputColorMatrix")
            sdf.setValue([vibrant], forKey: "filters")
        }

        sdf.setValue(highlight, forKey: "effect")

        let portal = portalClass.init()
        sdf.addSublayer(portal)
        portal.setValue(element, forKey: "sourceLayer")

        return sdf
    }
}

// MARK: - SwiftUI wrapper

/// SwiftUI host for the native glass pill. Mirrors `LiquidLensPill`'s shape API.
struct NativeGlassPill: NSViewRepresentable {
    var cornerRadius: CGFloat

    /// Whether the native private-API stack is usable on this OS build. The call
    /// site checks this (plus `#available(macOS 26)`) before choosing this path.
    static var isAvailable: Bool { PrivateGlassClasses.available }

    func makeNSView(context: Context) -> NativeGlassPillView {
        let v = NativeGlassPillView()
        v.cornerRadius = cornerRadius
        v.translatesAutoresizingMaskIntoConstraints = true
        return v
    }

    func updateNSView(_ v: NativeGlassPillView, context: Context) {
        v.cornerRadius = cornerRadius
    }
}
