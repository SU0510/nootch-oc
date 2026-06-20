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

    override func layout() {
        super.layout()
        relayout()
    }

    /// Recomputes uniforms, the zero-copy buffer size, and the shadow frame.
    /// Called from `layout()` and whenever the drawable size changes.
    private func relayout() {
        updateUniforms()

        let scale = scaleFactor
            * CGFloat(liquidGlass.backgroundTextureSizeCoefficient)
            * CGFloat(liquidGlass.backgroundTextureScaleCoefficient)
        let width = Int(bounds.width * scale)
        let height = Int(bounds.height * scale)
        if width > 0, height > 0 {
            zeroCopyBridge.setupBuffer(width: width, height: height)
        }

        shadowView?.frame = bounds
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
    /// The presentation layer is used wherever possible so the captured backdrop
    /// tracks the pill (and the content behind it) as it animates.
    func captureBackground() {
        guard let rootView = findRootView() else { return }

        let sizeCoefficient = CGFloat(liquidGlass.backgroundTextureSizeCoefficient)
        let scaleCoefficient = scaleFactor * CGFloat(liquidGlass.backgroundTextureScaleCoefficient)

        // Root layer to render. Prefer the presentation layer so in-flight
        // animation positions are captured rather than the final model state.
        let rootLayer = rootView.layer
        guard let rootLayer else { return }
        let srcLayer = rootLayer.presentation() ?? rootLayer

        // Our on-screen rect in the root layer's coordinate space, using the
        // presentation layer of self so the capture tracks our animated frame.
        let me = layer?.presentation() ?? layer
        guard let me else { return }
        let frameInRoot = me.convert(me.bounds, to: rootLayer)

        // Expand the capture area around the lens center (root layer coords).
        let captureSize = CGSize(width: frameInRoot.width * sizeCoefficient,
                                 height: frameInRoot.height * sizeCoefficient)
        let captureRectInRoot = CGRect(x: frameInRoot.midX - captureSize.width / 2,
                                       y: frameInRoot.midY - captureSize.height / 2,
                                       width: captureSize.width,
                                       height: captureSize.height)

        // The texture dimensions (matching the buffer set up in `relayout()`).
        let textureHeight = CGFloat(bounds.height) * scaleCoefficient * sizeCoefficient

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

            // Render the portion of the root layer under our capture rect:
            // scale to the texture's pixel density, then translate so the
            // capture-rect origin maps to the texture origin.
            context.scaleBy(x: scaleCoefficient, y: scaleCoefficient)
            context.translateBy(x: -captureRectInRoot.origin.x, y: -captureRectInRoot.origin.y)

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
