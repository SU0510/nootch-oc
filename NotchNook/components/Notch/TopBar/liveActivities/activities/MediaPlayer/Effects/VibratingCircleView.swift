//
//  VibratingCircleView.swift
//  NotchNook
//
//  Created by Lori Montenegro on 18/07/24.
//

import SwiftUI
import Cocoa

struct VibratingCircleView: NSViewRepresentable {
    var color: Color
    var isPlaying: Bool
    
    func makeNSView(context: Context) -> VibratingCircleNSView {
        let view = VibratingCircleNSView(frame: .zero)
        view.color = NSColor(color)
        view.startAnimating()
        return view
    }
    
    func updateNSView(_ nsView: VibratingCircleNSView, context: Context) {
        nsView.color = NSColor(color)
        nsView.isPlaying = isPlaying
    }
}

class VibratingCircleNSView: NSView {
    
    var color: NSColor = .nonShockingWhite {
        didSet {
            updateLayersColor()
            needsDisplay = true
        }
    }
    var isPlaying: Bool = false {
        didSet {
            if isPlaying {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }
    
    private var displayLink: CVDisplayLink?
    private var startTime: TimeInterval = 0
    private let amplitude: CGFloat = 3.0
    private let frequency: CGFloat = 2.0
    private let blur: CGFloat = 0.15
    private let velocity: CGFloat = 0.7
    private let smoothness: Int = 400
    private let lineWidth: CGFloat = 0.8
    private let noiseGenerator = PerlinNoiseGenerator()
    private let layerCount = 5
    private var layers: [CAShapeLayer] = []
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupLayers()
        setupDisplayLink()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupLayers()
        setupDisplayLink()
    }
    
    // MARK: - Setup
    
    private func setupLayers() {
        for i in 0..<layerCount {
            let shapeLayer = CAShapeLayer()
            shapeLayer.fillColor = nil
            shapeLayer.strokeColor = color.cgColor
            shapeLayer.lineWidth = lineWidth
            shapeLayer.shadowColor = color.cgColor
            shapeLayer.shadowRadius = blur
            shapeLayer.shadowOpacity = 1.0
            shapeLayer.shadowOffset = .zero
            let scale = 1.0 - (CGFloat(i) * 0.02)
            shapeLayer.transform = CATransform3DMakeScale(scale, scale, 1.0)
            layers.append(shapeLayer)
            layer?.addSublayer(shapeLayer)
        }
    }
    
    private func setupDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputHandler(displayLink!) { [weak self] (_, _, _, _, _) -> CVReturn in
            DispatchQueue.main.async {
                self?.updateLayers()
            }
            return kCVReturnSuccess
        }
    }
    
    // MARK: - Lifecycle
    
    deinit {
        stopAnimating()
    }
    
    override func layout() {
        super.layout()
        updateLayers()
    }
    
    // MARK: - Public Methods

    func startAnimating() {
        guard isPlaying else { return }
        if displayLink == nil {
            setupDisplayLink()
        }
        CVDisplayLinkStart(displayLink!)
    }
    
    func stopAnimating() {
        if displayLink != nil {
            CVDisplayLinkStop(displayLink!)
            displayLink = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func updateLayers() {
        let rect = calculateDrawingRect()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for (index, layer) in layers.enumerated() {
            let path = createVibratingCirclePath(center: center, radius: radius, layerIndex: index)
            layer.path = path
            layer.shadowRadius = blur
        }
    }
    
    private func updateLayersColor() {
        for layer in layers {
            layer.strokeColor = color.cgColor
            layer.shadowColor = color.cgColor
        }
    }
    
    private func createVibratingCirclePath(center: CGPoint, radius: CGFloat, layerIndex: Int) -> CGPath {
        let path = CGMutablePath()
        let numPoints = smoothness
        let angleIncrement = 2 * .pi / CGFloat(numPoints)
        let elapsedTime = getElapsedTime()
        
        for i in 0...numPoints {
            let angle = CGFloat(i) * angleIncrement
            let dynamicRadius = calculateDynamicRadius(angle: angle, elapsedTime: elapsedTime, baseRadius: radius, layerIndex: layerIndex)
            if dynamicRadius.isNaN || dynamicRadius.isInfinite {
                continue
            }
            let point = calculatePoint(center: center, radius: dynamicRadius, angle: angle)
            addPointToPath(path: path, point: point, isFirstPoint: i == 0)
        }
        path.closeSubpath()
        return path
    }
    
    private func calculateDynamicRadius(angle: CGFloat, elapsedTime: CGFloat, baseRadius: CGFloat, layerIndex: Int) -> CGFloat {
        let layerAmplitude = amplitude * (CGFloat(layerIndex + 1) / CGFloat(layerCount))
        
        let adjustedTime = elapsedTime * velocity
        
        let noiseValue = noiseGenerator.noise(x: Double(angle), y: Double(adjustedTime), z: Double(layerIndex))
        let dynamicOffset = CGFloat(noiseValue) * layerAmplitude
        
        return baseRadius + dynamicOffset
    }

    private func calculateDrawingRect() -> CGRect {
        let minimumDimension = min(bounds.width, bounds.height)
        let insetAmount = minimumDimension / 10
        return bounds.insetBy(dx: insetAmount, dy: insetAmount)
    }

    private func createVibratingCirclePath(center: CGPoint, radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let numPoints = 100
        let angleIncrement = 2 * .pi / CGFloat(numPoints)
        let elapsedTime = getElapsedTime()

        for i in 0...numPoints {
            let angle = CGFloat(i) * angleIncrement
            let dynamicRadius = calculateDynamicRadius(angle: angle, elapsedTime: elapsedTime, baseRadius: radius)
            if dynamicRadius.isNaN || dynamicRadius.isInfinite {
                continue
            }
            let point = calculatePoint(center: center, radius: dynamicRadius, angle: angle)
            addPointToPath(path: path, point: point, isFirstPoint: i == 0)
        }
        path.closeSubpath()
        return path
    }

    private func getElapsedTime() -> CGFloat {
        let currentTime = CACurrentMediaTime()
        if startTime == 0 { startTime = currentTime }
        return CGFloat(currentTime - startTime)
    }

    private func calculateDynamicRadius(angle: CGFloat, elapsedTime: CGFloat, baseRadius: CGFloat) -> CGFloat {
        return baseRadius + sin(elapsedTime * frequency + angle * CGFloat(100 / 5)) * amplitude
    }

    private func calculatePoint(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        let x = center.x + radius * cos(angle)
        let y = center.y + radius * sin(angle)
        return CGPoint(x: x, y: y)
    }

    private func addPointToPath(path: CGMutablePath, point: CGPoint, isFirstPoint: Bool) {
        if isFirstPoint {
            path.move(to: point)
        } else {
            path.addLine(to: point)
        }
    }
}
