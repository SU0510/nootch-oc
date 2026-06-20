//
//  LiquidLensView.swift
//  NotchNook
//
//  AppKit (macOS) port of LiquidGlassKit's UIKit `LiquidGlassView: MTKView`,
//  wrapped as a SwiftUI `NSViewRepresentable` (`LiquidLensPill`).
//
//  This file ports ONLY the rendering view (and the shadow overlay). The types
//  `LiquidGlass`, `LiquidGlass.ShaderUniforms`, `LiquidGlassRenderer`, and
//  `ZeroCopyBridge` are defined in sibling files and are used here as-is.
//

import AppKit
import MetalKit
import SwiftUI
import simd
import MetalPerformanceShaders

// MARK: - Shadow overlay

/// A lightweight multiply-blend shadow ring drawn on top of the lens, matching
/// the UIKit `ShadowView`. Purely decorative; ignores hit-testing.
final class LiquidLensShadowView: NSView {

    override var isFlipped: Bool { true }

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        // Multiply blend so the shadow darkens whatever is behind it.
        layer?.compositingFilter = "multiplyBlendMode"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        guard let layer else { return }

        let shadowRadius: CGFloat = 3.5
        // Outer pill (slightly inset vertically, expanded horizontally) minus an
        // inner pill cutout = a soft ring shadow hugging the lens silhouette.
        let outerRect = bounds.insetBy(dx: -1, dy: -shadowRadius / 2)
        let innerRect = bounds.insetBy(dx: 0, dy: shadowRadius / 2)

        let path = CGMutablePath()
        path.addRoundedRect(in: outerRect,
                            cornerWidth: outerRect.height / 2,
                            cornerHeight: outerRect.height / 2)
        // Reverse winding for the inner cutout by adding it as a separate
        // sub-path; using even-odd shadow path semantics gives the ring.
        path.addRoundedRect(in: innerRect,
                            cornerWidth: innerRect.height / 2,
                            cornerHeight: innerRect.height / 2)

        layer.shadowPath = path
        layer.shadowRadius = shadowRadius
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: shadowRadius + 2)
        layer.shadowColor = NSColor.black.cgColor
    }
}

// MARK: - LiquidLensView

/// AppKit port of `LiquidGlassView`. A Metal-backed view that renders the
/// liquid-glass refraction effect over a captured snapshot of the content
/// behind it.
final class LiquidLensView: MTKView {

    let liquidGlass: LiquidGlass

    var commandQueue: MTLCommandQueue!
    var uniformsBuffer: MTLBuffer!
    var zeroCopyBridge: ZeroCopyBridge!

    /// Background texture for the shader (the captured backdrop).
    private var backgroundTexture: MTLTexture?

    /// Whether to automatically capture the content behind the view on each
    /// frame. Set to false for manual control via `captureBackground()`.
    var autoCapture: Bool = true

    var touchPoint: CGPoint? = nil

    var frames: [CGRect] = []

    /// The lens's current rect within the world-anchored capture region, in uv
    /// (0..1, top-left origin). Computed in `captureBackground()` from the SAME
    /// layer snapshot used to render the texture, then fed to the shader by
    /// `updateUniforms()`. Defaults map the lens to the whole texture (identity)
    /// until the first capture runs.
    private var lensOriginInCapture: SIMD2<Float> = .zero
    private var lensSizeInCapture: SIMD2<Float> = .init(1, 1)

    /// Optional multiply-blend shadow overlay subview.
    private weak var shadowView: LiquidLensShadowView?

    /// The hosting view is flipped (top-left origin) to match the shader's
    /// upper-left coordinate expectations.
    override var isFlipped: Bool { true }

    init(_ liquidGlass: LiquidGlass) {
        self.liquidGlass = liquidGlass

        super.init(frame: .zero, device: LiquidGlassRenderer.shared.device)

        wantsLayer = true

        if liquidGlass.shadowOverlay {
            let shadowView = LiquidLensShadowView()
            addSubview(shadowView)
            self.shadowView = shadowView
        }

        setupMetal()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func setupMetal() {
        guard let device else { return }

        commandQueue = device.makeCommandQueue()!

        // Uniforms buffer (updated per frame).
        uniformsBuffer = device.makeBuffer(length: MemoryLayout<LiquidGlass.ShaderUniforms>.stride,
                                           options: [])!

        zeroCopyBridge = .init(device: device)

        // Transparent drawable so the effect composites over the content behind.
        colorPixelFormat = .bgra8Unorm
        clearColor = MTLClearColorMake(0, 0, 0, 0)
        layer?.isOpaque = false

        // Drive a continuous render loop: MTKView's internal CVDisplayLink calls
        // our delegate every frame. We act as our own delegate (via a small
        // private forwarder) so `render()` runs each vsync without relying on
        // `setNeedsDisplay`.
        isPaused = false
        enableSetNeedsDisplay = false
        // Run at the display's native max refresh (120 on ProMotion, 60 on a
        // standard panel) rather than a hard 60 cap. The MTKView drawable is
        // vsync'd, so this tracks the monitor instead of truly free-running.
        // Refreshed in `relayout()` once the window/screen is known and whenever
        // the view moves to a display with a different refresh rate.
        preferredFramesPerSecond = maxRefreshRate
        delegate = renderDelegate
    }

    // Strongly-held delegate forwarder. MTKView holds its delegate weakly, so
    // we keep it alive here.
    private lazy var renderDelegate = LiquidLensRenderDelegate(view: self)

    // MARK: - Layout

    /// macOS scale factor. Mirrors what UIKit got from `layer.contentsScale`.
    private var scaleFactor: CGFloat {
        window?.backingScaleFactor ?? layer?.contentsScale ?? 2
    }

    /// The active display's maximum refresh rate (e.g. 120 on ProMotion, 60 on a
    /// standard panel). Used to drive the render loop at the monitor's native
    /// cadence instead of a hard 60 cap. Falls back to 60 before the view is
    /// attached to a screen.
    private var maxRefreshRate: Int {
        let rate = (window?.screen ?? NSScreen.main)?.maximumFramesPerSecond ?? 60
        return max(rate, 60)
    }

    override func layout() {
        super.layout()
        relayout()
    }

    /// Recomputes uniforms, the zero-copy buffer size, and the shadow frame.
    /// Called from `layout()` and whenever the drawable size changes.
    private func relayout() {
        updateUniforms()

        // Track the current display's native refresh (the view may now be
        // attached to a window/screen that wasn't known at init, or have moved
        // to a panel with a different rate).
        let rate = maxRefreshRate
        if preferredFramesPerSecond != rate {
            preferredFramesPerSecond = rate
        }

        // Buffer is sized to the WORLD-ANCHORED capture region (the stationary
        // container the pill slides within), not the pill — see `captureRegion`.
        // The region is stable during a slide (only the pill offsets within it),
        // so `setupBuffer`'s size-guard still holds and no per-frame realloc fires.
        let region = captureRegionSize
        let scale = scaleFactor * CGFloat(liquidGlass.backgroundTextureScaleCoefficient)
        let width = Int(region.width * scale)
        let height = Int(region.height * scale)
        if width > 0, height > 0 {
            zeroCopyBridge.setupBuffer(width: width, height: height)
        }

        shadowView?.frame = bounds
    }

    /// The world-anchored capture region: the nearest STATIONARY ancestor that
    /// is wider than the pill — i.e. the wheel-group container the pill slides
    /// within. SwiftUI's `.offset` repositions the pill *inside* this container,
    /// so the container itself does NOT move during a slide → the captured
    /// texture stays valid frame-to-frame and the pill is just indexed into it by
    /// uv.
    ///
    /// Crucially this is SMALL (3 columns, one row) — capturing it is cheap.
    /// Capturing the whole root instead (an earlier mistake) rasterized the
    /// full-width notch every frame via `CALayer.render(in:)`, which is ~100×
    /// the pixels and tanked the frame rate. Cost scales with region pixel area,
    /// so the region must hug the pill's travel, not the screen.
    ///
    /// Falls back to the root only if no wider ancestor exists yet.
    private func captureHostView() -> NSView? {
        let minWidth = bounds.width * 1.5
        var current = superview
        while let v = current {
            if v.bounds.width >= minWidth, v.bounds.height > 0 { return v }
            current = v.superview
        }
        return findRootView()
    }

    /// Size (in points) of the world-anchored capture region. Pill-based fallback
    /// (legacy pill-centered behavior) before the view is attached.
    private var captureRegionSize: CGSize {
        captureHostView()?.bounds.size
            ?? CGSize(width: bounds.width * CGFloat(liquidGlass.backgroundTextureSizeCoefficient),
                      height: bounds.height * CGFloat(liquidGlass.backgroundTextureSizeCoefficient))
    }

    // MARK: - Background Capture

    /// Captures the app content **behind** the lens and feeds it as the shader's
    /// background texture.
    ///
    /// macOS port of the UIKit `captureRootView()`. UIKit's `drawHierarchy`
    /// path (`captureBackdrop`) has no clean AppKit equivalent without private
    /// `CABackdropLayer` APIs, so we always render the root content view's
    /// `CALayer` directly via `CALayer.render(in:)`.
    ///
    /// World-anchored capture: the texture covers a FIXED region (the whole
    /// stationary root) — it does NOT track the pill. The pill's current rect
    /// within that region is computed as uv and handed to the shader, which
    /// indexes the backdrop by world position. Through-glass content is therefore
    /// world-fixed by construction, with no opposing-motion cancellation that
    /// could leak as lateral drift.
    func captureBackground() {
        guard let rootView = findRootView() else { return }

        let scaleCoefficient = scaleFactor * CGFloat(liquidGlass.backgroundTextureScaleCoefficient)

        // Root layer to render. Prefer the presentation layer so in-flight
        // animation positions are captured rather than the final model state.
        let rootLayer = rootView.layer
        guard let rootLayer else { return }
        let srcLayer = rootLayer.presentation() ?? rootLayer

        // Presentation layer of the pill — computed in the SAME (presentation)
        // layer tree as `srcLayer` so positions are mutually consistent while
        // ancestors animate (model ≠ presentation mid-animation; mixing them was
        // the old drift).
        guard let me = layer?.presentation() ?? layer else { return }

        // The WORLD-ANCHORED capture region = the stationary host (wheel-group
        // container) in root coords. We still render the full root layer into the
        // context (so content is complete), but offset so the host's rect maps to
        // the texture origin. The host doesn't move during a slide, so this origin
        // is stable frame-to-frame and the pill is just indexed into it by uv.
        let hostView = captureHostView()
        let hostLayer = hostView?.layer.flatMap { $0.presentation() ?? $0 }
        let regionOrigin = hostLayer.map { $0.convert(CGPoint.zero, to: srcLayer) } ?? .zero
        let regionSize = captureRegionSize

        // The pill's rect within that region. CENTER comes from the pill's
        // presentation layer (tracks the in-flight slide); SIZE comes from the
        // unscaled `bounds`, NOT the presentation frame — the keyframe stretch
        // pulse applies a `scaleEffect` (1.0→1.35) to the presentation layer, so
        // using the presentation size would zoom the backdrop mid-travel. Stable
        // bounds size keeps the backdrop 1:1 with the render.
        let lensFrameInRoot = me.convert(me.bounds, to: srcLayer)
        let lensCenter = CGPoint(x: lensFrameInRoot.midX, y: lensFrameInRoot.midY)
        let lensSize = bounds.size
        let lensOrigin = CGPoint(x: lensCenter.x - lensSize.width / 2,
                                 y: lensCenter.y - lensSize.height / 2)

        // Lens rect → uv within the capture region (top-left origin). The shader
        // maps each fragment's pill-local uv (0..1) through this to the texture.
        lensOriginInCapture = SIMD2<Float>(
            Float((lensOrigin.x - regionOrigin.x) / regionSize.width),
            Float((lensOrigin.y - regionOrigin.y) / regionSize.height)
        )
        lensSizeInCapture = SIMD2<Float>(
            Float(lensSize.width / regionSize.width),
            Float(lensSize.height / regionSize.height)
        )

        // The texture dimensions (matching the buffer set up in `relayout()`).
        let textureHeight = regionSize.height * scaleCoefficient

        backgroundTexture = zeroCopyBridge.render { context in
            // Hide self during capture so the lens doesn't sample itself.
            let wasHidden = isHidden
            isHidden = true
            defer { isHidden = wasHidden }

            // --- CRITICAL Y-FLIP ---
            // The CGContext backing the CVPixelBuffer is bottom-left origin (as
            // are all CoreGraphics bitmap contexts). `CALayer.render(in:)` draws
            // in the layer's own coordinate system. The shader, however, treats
            // the background texture as upper-left origin (its rects, touchPoint
            // and `uv` math all assume top-left). The app's hosting view is
            // flipped (top-left origin) as well.
            //
            // To deliver an upper-left-origin image to the shader we flip the
            // context vertically before rendering: move the origin to the top of
            // the texture, then invert the Y axis. After this, `render(in:)`
            // output reads top-down to match the shader's sampling.
            //
            // NOTE: if the refraction ever looks vertically mirrored, this is the
            // single knob to flip — remove (or re-add) this transform pair.
            context.translateBy(x: 0, y: textureHeight)
            context.scaleBy(x: 1, y: -1)

            // Render the portion of the root layer under our (world-anchored)
            // capture region: scale to the texture's pixel density, then translate
            // so the region's origin maps to the texture origin.
            context.scaleBy(x: scaleCoefficient, y: scaleCoefficient)
            context.translateBy(x: -regionOrigin.x, y: -regionOrigin.y)

            srcLayer.render(in: context)
        }

        blurTexture()
    }

    /// GPU Gaussian blur of the background texture.
    ///
    /// No-op when `backgroundTextureBlurRadius <= 0` (the `.lens` preset uses 0,
    /// so this early-returns and the blur step is effectively disabled).
    func blurTexture() {
        guard liquidGlass.backgroundTextureBlurRadius > 0,
              let device,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              var backgroundTexture else { return }

        // Scale the blur radius to pixels.
        let sigma = Float(liquidGlass.backgroundTextureBlurRadius * Double(scaleFactor))
        let blur = MPSImageGaussianBlur(device: device, sigma: sigma)
        blur.edgeMode = .clamp

        blur.encode(commandBuffer: commandBuffer,
                    inPlaceTexture: &backgroundTexture,
                    fallbackCopyAllocator: nil)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    // MARK: - Uniforms

    func updateUniforms() {
        var uniforms = liquidGlass.shaderUniforms
        let scaleFactor = self.scaleFactor

        uniforms.resolution = .init(x: Float(bounds.width * scaleFactor),
                                    y: Float(bounds.height * scaleFactor))
        uniforms.contentsScale = Float(scaleFactor)

        uniforms.shapeMergeSmoothness = 0.2

        // World-anchored capture mapping. Computed in `captureBackground()` from
        // the same presentation-layer snapshot used to render the texture, so the
        // lens's uv rect within the fixed capture region is consistent with the
        // rendered pixels (no drift). `render()` calls captureBackground() before
        // updateUniforms() each frame, so these are fresh.
        uniforms.lensOriginInCapture = lensOriginInCapture
        uniforms.lensSizeInCapture = lensSizeInCapture

        // Assign rectangles from `frames`, or fall back to the view bounds.
        let effectiveFrames = frames.isEmpty ? [bounds] : frames
        uniforms.rectangleCount = Int32(min(effectiveFrames.count, LiquidGlass.maxRectangles))

        // Convert CGRect frames to SIMD4<Float> (x, y, width, height).
        var rects: [SIMD4<Float>] = []
        for i in 0..<LiquidGlass.maxRectangles {
            if i < effectiveFrames.count {
                let frame = effectiveFrames[i]
                rects.append(SIMD4<Float>(
                    Float(frame.origin.x),
                    Float(frame.origin.y),
                    Float(frame.width),
                    Float(frame.height)
                ))
            } else {
                rects.append(.zero)
            }
        }
        uniforms.rectangles = (
            rects[0], rects[1], rects[2], rects[3],
            rects[4], rects[5], rects[6], rects[7],
            rects[8], rects[9], rects[10], rects[11],
            rects[12], rects[13], rects[14], rects[15]
        )

        if let touchPoint {
            uniforms.touchPoint = .init(x: Float(touchPoint.x), y: Float(touchPoint.y))
        }

        uniforms.cornerRadius = Float(layer?.cornerRadius ?? 0)

        if let tintColor = liquidGlass.tintColor {
            uniforms.materialTint = tintColor.toLiquidLensSimdFloat4()
        }

        uniformsBuffer.contents()
            .assumingMemoryBound(to: LiquidGlass.ShaderUniforms.self)
            .pointee = uniforms
    }

    // MARK: - Render

    /// Renders one frame. Driven continuously by the MTKView display loop via
    /// `LiquidLensRenderDelegate`.
    func render() {
        // Auto-capture the content behind us if enabled.
        if autoCapture {
            captureBackground()
        }

        // Keep uniforms fresh (cornerRadius / bounds can change between layouts).
        updateUniforms()

        guard let drawable = currentDrawable,
              let renderPassDesc = currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc) else { return }

        encoder.setRenderPipelineState(LiquidGlassRenderer.shared.pipelineState)
        encoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)

        if let texture = backgroundTexture {
            encoder.setFragmentTexture(texture, index: 0)
        }

        // Fullscreen quad (vertices generated in the vertex shader).
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - Render delegate

/// Small forwarder so `LiquidLensView` can drive its own continuous render loop
/// through MTKView's display link without subclassing the delegate machinery.
private final class LiquidLensRenderDelegate: NSObject, MTKViewDelegate {
    weak var view: LiquidLensView?

    init(view: LiquidLensView) {
        self.view = view
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Drawable size changes are handled in `layout()` / `relayout()`.
    }

    func draw(in view: MTKView) {
        self.view?.render()
    }
}

// MARK: - NSColor helper

extension NSColor {
    /// Converts the color to a premultiplied-agnostic RGBA `SIMD4<Float>` in the
    /// sRGB space the shader expects.
    func toLiquidLensSimdFloat4() -> SIMD4<Float> {
        // `getRed(_:...)` requires an RGB-compatible color space.
        let rgb = usingColorSpace(.sRGB) ?? self
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgb.getRed(&r, green: &g, blue: &b, alpha: &a)
        return .init(x: Float(r), y: Float(g), z: Float(b), w: Float(a))
    }
}

// MARK: - View hierarchy helper

extension NSView {
    /// Finds the topmost (root) view in the view hierarchy by walking up
    /// `superview` until there is no parent.
    func findRootView() -> NSView? {
        var current: NSView? = superview
        while let parent = current?.superview {
            current = parent
        }
        return current
    }
}

// MARK: - SwiftUI wrapper

/// SwiftUI wrapper hosting a `LiquidLensView`. The hosting SwiftUI layout sizes
/// the view; we only feed through the corner radius (which the shader reads from
/// `layer.cornerRadius`).
struct LiquidLensPill: NSViewRepresentable {
    var cornerRadius: CGFloat

    func makeNSView(context: Context) -> LiquidLensView {
        let v = LiquidLensView(.lens)
        v.wantsLayer = true
        v.layer?.cornerRadius = cornerRadius
        v.layer?.masksToBounds = true
        v.layer?.isOpaque = false
        // Hosted by SwiftUI, which sizes the view via its own layout.
        v.translatesAutoresizingMaskIntoConstraints = true
        return v
    }

    func updateNSView(_ v: LiquidLensView, context: Context) {
        // The shader reads cornerRadius from `layer.cornerRadius` in
        // `updateUniforms()`, so updating the layer is sufficient.
        v.layer?.cornerRadius = cornerRadius
    }
}
