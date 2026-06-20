//
//  LiquidGlassRenderer.swift
//  NotchNook
//
//  Ported from LiquidGlassKit (UIKit) to AppKit (macOS).
//  Original by Alexey Demin on 2025-12-05.
//
//  This file ports ONLY the `LiquidGlass` struct (with its nested `ShaderUniforms`),
//  the static presets, and the `LiquidGlassRenderer` class. The MTKView/NSView,
//  BackdropView and ShadowView parts are handled elsewhere.
//

import Foundation
import Metal
import AppKit   // for NSColor
import simd

struct LiquidGlass {

    /// Maximum number of rectangles supported in the shader.
    static let maxRectangles = 16

    /// Mirror the Metal 'ShaderUniforms' exactly for buffer binding.
    struct ShaderUniforms {
        var resolution: SIMD2<Float> = .zero        // Frame size in pixels.
        var contentsScale: Float = .zero            // Scale factor. 2 for Retina; 3 for Super Retina.
        var touchPoint: SIMD2<Float> = .zero        // Touch position in points (upper-left origin).
        var shapeMergeSmoothness: Float = .zero     // Specifies the distance between elements at which they begin to merge (spacing).
        var cornerRadius: Float = .zero             // Base rounding (e.g., 24 for subtle chamfer). Circle if half the side.
        var cornerRoundnessExponent: Float = 2      // 1 = diamond; 2 = circle; 4 = squircle.
        var materialTint: SIMD4<Float> = .zero      // RGBA; e.g., subtle cyan (0.2, 0.8, 1.0, 1.0)
        var glassThickness: Float                   // Fake parallax depth (e.g., 8-16 px)
        var refractiveIndex: Float                  // 1.45-1.52 for borosilicate glass feel
        var dispersionStrength: Float               // 0.0-0.02; prismatic color split on edges
        var fresnelDistanceRange: Float             // px falloff from silhouette (e.g., 32)
        var fresnelIntensity: Float                 // 0.0-1.0; rim lighting boost
        var fresnelEdgeSharpness: Float             // Power 1.0=linear, 8.0=crisp
        var glareDistanceRange: Float               // Similar to fresnel, but for specular streaks
        var glareAngleConvergence: Float            // 0.0-π; focuses rays toward light dir
        var glareOppositeSideBias: Float            // >1.0 amplifies back-side highlights
        var glareIntensity: Float                   // 1.0-4.0; bloom-like edge fire
        var glareEdgeSharpness: Float               // Matches fresnel for consistency
        var glareDirectionOffset: Float             // Radians; tilts streak asymmetry
        var rectangleCount: Int32 = .zero           // Number of active rectangles
        var rectangles: (                           // Array of rectangles (x, y, width, height) in points, upper-left origin.
            SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
            SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
            SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
            SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>
        ) = (.zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero,
             .zero, .zero, .zero, .zero, .zero, .zero, .zero, .zero)
        // World-anchored capture mapping. The background texture covers a FIXED,
        // stationary region (the whole root layer), so through-glass content is
        // indexed by world position rather than by re-centering a pill-tracking
        // window — eliminating the opposing-motion cancellation that leaked as
        // lateral drift. `lensOriginInCapture` is the uv (top-left origin) of the
        // lens's current rect within that region; `lensSizeInCapture` is its
        // uv-space size. Appended at the END so existing field offsets (Swift↔Metal
        // struct-layout parity) are unchanged.
        var lensOriginInCapture: SIMD2<Float> = .zero
        var lensSizeInCapture: SIMD2<Float> = .init(1, 1)
    }

    let shaderUniforms: ShaderUniforms
    let backgroundTextureSizeCoefficient: Double
    let backgroundTextureScaleCoefficient: Double
    let backgroundTextureBlurRadius: Double
    var tintColor: NSColor?
    var shadowOverlay: Bool = false

    static func thumb(magnification: Double = 1) -> Self {
        .init(
            shaderUniforms: .init(
                materialTint: .init(x: 0.9, y: 0.95, z: 1.0, w: 0.15), // Near-clear with cool bias.
                glassThickness: 10,
                refractiveIndex: 1.11,
                dispersionStrength: 5,
                fresnelDistanceRange: 70,
                fresnelIntensity: 0,
                fresnelEdgeSharpness: 0,
                glareDistanceRange: 30,
                glareAngleConvergence: 0,
                glareOppositeSideBias: 0,
                glareIntensity: 0.01,
                glareEdgeSharpness: -0.2,
                glareDirectionOffset: .pi * 0.9
            ),
            backgroundTextureSizeCoefficient: 1 / magnification,
            backgroundTextureScaleCoefficient: magnification,
            backgroundTextureBlurRadius: 0,
            shadowOverlay: true
        )
    }

    static let lens = Self.init(
        shaderUniforms: .init(
            glassThickness: 6,
            refractiveIndex: 1.1,
            dispersionStrength: 15,
            fresnelDistanceRange: 70,
            fresnelIntensity: 0,
            fresnelEdgeSharpness: 0,
            glareDistanceRange: 30,
            glareAngleConvergence: 0.1,
            glareOppositeSideBias: 1,
            glareIntensity: 0.1,
            glareEdgeSharpness: -0.1,
            glareDirectionOffset: -.pi / 4
        ),
        backgroundTextureSizeCoefficient: 1.1,
        backgroundTextureScaleCoefficient: 0.8,
        backgroundTextureBlurRadius: 0,
        shadowOverlay: true
    )

    static let regular = Self.init(
        shaderUniforms: .init(
            glassThickness: 10,
            refractiveIndex: 1.5,
            dispersionStrength: 5,
            fresnelDistanceRange: 70,
            fresnelIntensity: 0,
            fresnelEdgeSharpness: 0,
            glareDistanceRange: 30,
            glareAngleConvergence: 0.1,
            glareOppositeSideBias: 1,
            glareIntensity: 0.1,
            glareEdgeSharpness: -0.15,
            glareDirectionOffset: -.pi / 4
        ),
        backgroundTextureSizeCoefficient: 1,
        backgroundTextureScaleCoefficient: 0.2,
        backgroundTextureBlurRadius: 0.3,
        // Dynamic tint: dark vs light appearance (mirrors the source's dynamic UIColor).
        tintColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark
                ? NSColor(srgbRed: 0, green: 0.04958364581, blue: 0.09951775161, alpha: 0.7981493615)
                : NSColor(srgbRed: 0.9023525731, green: 0.9509486998, blue: 1, alpha: 0.8002892298)
        }
    )
}

@MainActor
final class LiquidGlassRenderer {
    static let shared = LiquidGlassRenderer()

    let device: MTLDevice
    let pipelineState: MTLRenderPipelineState

    private init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal not supported")
        }
        self.device = device

        // In the app target the two .metal files compile into the app's default
        // Metal library, so we build the pipeline from `makeDefaultLibrary()`.
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to load default Metal library")
        }

        let vertexFunction = library.makeFunction(name: "fullscreenQuad")!
        let fragmentFunction = library.makeFunction(name: "liquidGlassEffect")!

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm  // Match MTKView

        self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}

extension NSColor {
    func toSimdFloat4() -> SIMD4<Float> {
        // NSColor crashes if components are read from a non-RGB color space, so
        // convert to sRGB first (falls back to the original color if conversion fails).
        let rgb = usingColorSpace(.sRGB) ?? self
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgb.getRed(&r, green: &g, blue: &b, alpha: &a)
        return .init(x: Float(r), y: Float(g), z: Float(b), w: Float(a))
    }
}
