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
        return view
    }
    
    func updateNSView(_ nsView: VibratingCircleNSView, context: Context) {
        nsView.color = NSColor(color)
        nsView.isPlaying = isPlaying
    }
    
    static func dismantleNSView(_ nsView: VibratingCircleNSView, coordinator: ()) {
        nsView.isPlaying = false
        nsView.cleanup()
        nsView.removeFromSuperview()
    }
}

class VibratingCircleNSView: NSView {
    
    var color: NSColor = .nonShockingWhite {
        didSet {
            updateLayersColor()
        }
    }
    var isPlaying: Bool = false {
        didSet {
            isPlaying ? startAnimating() : stopAnimating()
        }
    }
    
    private var displayLinkHandler: DisplayLinkHandler?

    private var startTime: TimeInterval = 0
    private let updateInterval: TimeInterval = 1.0 / 10.0 // 10 FPS is enough for this effect
    private var lastUpdateTime: TimeInterval = 0
    private let amplitude: CGFloat = 3.0
    private let frequency: CGFloat = 2.0
    private let blur: CGFloat = 0.15
    private let velocity: CGFloat = 0.7
    private let lineWidth: CGFloat = 0.8
    private let noiseGenerator = PerlinNoiseGenerator()
    private let layerCount = 4
    private var layers: [CAShapeLayer] = []
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
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
        displayLinkHandler = DisplayLinkHandler(target: self, fps: 10) { [weak self] in
            self?.updateLayers()
        }
    }
    
    // MARK: - Lifecycle
    
    override func layout() {
        super.layout()
        updateLayers()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods

    func startAnimating() {
        guard isPlaying else { return }
        setupDisplayLink()
        displayLinkHandler?.start()
    }
    
    func stopAnimating() {
        displayLinkHandler?.stop()
        lastUpdateTime = 0
        startTime = 0
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layers.forEach { $0.removeAllAnimations() }
        CATransaction.commit()
    }
    
    func cleanup() {
        stopAnimating()
        displayLinkHandler = nil
        layers.forEach { $0.removeFromSuperlayer() }
        layers.removeAll()
        layer?.sublayers?.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func updateLayers() {
        guard !layers.isEmpty else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let rect = calculateDrawingRect()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for (index, layer) in layers.enumerated() {
            if layer.superlayer == nil {
                self.layer?.addSublayer(layer)
            }
            layer.path = createVibratingCirclePath(center: center, radius: radius, layerIndex: index)
        }
        
        CATransaction.commit()
    }
    
    private func updateLayersColor() {
        for layer in layers {
            layer.strokeColor = color.cgColor
            layer.shadowColor = color.cgColor
        }
    }
    
    private func createVibratingCirclePath(center: CGPoint, radius: CGFloat, layerIndex: Int) -> CGPath {
        let path = CGMutablePath()
        let numPoints = 50
        let angleIncrement = 2 * .pi / CGFloat(numPoints)
        let elapsedTime = getElapsedTime()
        
        var points = [CGPoint]()
        points.reserveCapacity(numPoints + 1)
        
        for i in 0...numPoints {
            let angle = CGFloat(i) * angleIncrement
            let dynamicRadius = calculateDynamicRadius(angle: angle, elapsedTime: elapsedTime, baseRadius: radius, layerIndex: layerIndex)
            if dynamicRadius.isNaN || dynamicRadius.isInfinite { continue }
            points.append(calculatePoint(center: center, radius: dynamicRadius, angle: angle))
        }
        
        if let first = points.first {
            path.move(to: first)
            points.forEach { path.addLine(to: $0) }
            path.closeSubpath()
        }
        
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

    private func getElapsedTime() -> CGFloat {
        let currentTime = CACurrentMediaTime()
        if startTime == 0 { startTime = currentTime }
        return CGFloat(currentTime - startTime)
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
