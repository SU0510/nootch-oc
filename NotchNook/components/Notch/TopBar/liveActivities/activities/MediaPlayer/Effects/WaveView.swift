//
//  WaveView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 06/07/24.
//

import SwiftUI
import QuartzCore
import CoreImage
import CoreGraphics
import CoreImage.CIFilterBuiltins
import Cocoa
import DynamicColor

struct WaveView: NSViewRepresentable {
    var volume: Double
    var color: Color
    
    func makeNSView(context: Context) -> WaveNSView {
        let view = WaveNSView(frame: .zero)
        view.startRandomMovement()
        return view
    }
    
    func updateNSView(_ nsView: WaveNSView, context: Context) {
        nsView.color = NSColor(color)
        nsView.volume = volume
    }
    
    static func dismantleNSView(_ nsView: WaveNSView, coordinator: ()) {
        nsView.cleanup()
    }
}

class WaveNSView: NSView {
    var volume: Double = 1
    var color: NSColor = .white {
        didSet {
            updateLayerColors()
        }
    }
    
    private struct MiddlePoint {
        var control: CGPoint
        var direction1: CGPoint
        var direction2: CGPoint
    }
    
    private var middlePoints: [MiddlePoint]
    private var movementTimer: Timer?
    private var blurFilter = CIFilter(name: "CIGaussianBlur")!
    private lazy var shapeLayers: [[CAShapeLayer]] = createShapeLayers()
    
    private var isBeingDeallocated = false
    
    init(frame frameRect: NSRect, linesCount: Int = 3) {
        middlePoints = Array(
            repeating: MiddlePoint(control: .zero, direction1: .zero, direction2: .zero),
            count: linesCount
        )
        super.init(frame: frameRect)
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func changeBlur(to radius: Double) {
        let animation = CABasicAnimation(keyPath: "filters.blur.inputRadius")
        animation.timingFunction = .init(name: .easeInEaseOut)
        animation.duration = 1
        animation.fromValue = nil
        animation.toValue = radius
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        layer?.add(animation, forKey: nil)
    }
    
    func moveControlPoint(to newControlPoint: CGPoint, direction1 newDirectionPoint1: CGPoint, direction2 newDirectionPoint2: CGPoint, baseY newBaseY: CGFloat, withAnimationDuration duration: TimeInterval, index: Int) {
        guard index < shapeLayers.count else { return }
        let innerLayers = shapeLayers[index]
        Array(innerLayers.enumerated()).forEach { i, layer in
            let animation = CABasicAnimation(keyPath: "path")
            animation.timingFunction = .init(name: .easeInEaseOut)
            animation.duration = duration
            animation.fromValue = layer.presentation()?.path
            animation.isRemovedOnCompletion = true
            
            let newPath = NSBezierPath()
            newPath.move(to: CGPoint(x: bounds.minX, y: bounds.midY))
            newPath.curve(to: CGPoint(x: bounds.maxX, y: newBaseY), controlPoint1: newDirectionPoint1, controlPoint2: newDirectionPoint2)
            animation.toValue = newPath.cgPath
            
            layer.add(animation, forKey: "pathAnimation")
            layer.path = newPath.cgPath
            
            if index < middlePoints.count {
                middlePoints[index] = MiddlePoint(control: newControlPoint, direction1: newDirectionPoint1, direction2: newDirectionPoint2)
            }
        }
    }
    
    func startRandomMovement() {
        stopRandomMovement()
        movementTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.randomizeMovement()
        }
    }
    
    func stopRandomMovement() {
        movementTimer?.invalidate()
        movementTimer = nil
    }
    
    private func createShapeLayers() -> [[CAShapeLayer]] {
        var layers = [[CAShapeLayer]]()
        for i in 0..<middlePoints.count {
            var innerLayers = [CAShapeLayer]()
            for _ in 0..<2 {
                let layer = CAShapeLayer()
                layer.strokeColor = color.darkened(amount: CGFloat(i) * 0.2).cgColor
                layer.lineWidth = 1
                layer.fillColor = NSColor.clear.cgColor
                layer.name = "\(i)"
                innerLayers.append(layer)
                layer.zPosition = CGFloat(middlePoints.count - i)
                self.layer?.addSublayer(layer)
            }
            layers.append(innerLayers)
        }
        return layers
    }
    
    private func setupLayer() {
        wantsLayer = true
        layer = CALayer()
        blurFilter.name = "blur"
        layer?.filters = [blurFilter]
        layer?.setValue(0, forKeyPath: "filters.blur.inputRadius")
    }
    
    private func updateLayerColors() {
        shapeLayers.forEach { layers in
            layers.forEach { layer in
                guard let index = Int(layer.name ?? "0") else { return }
                let value = CGFloat(index)
                layer.strokeColor = color.darkened(amount: value * 0.1).shaded(amount: value * 0.2).cgColor
            }
        }
    }
    
    private func randomizeMovement() {
        for i in 0..<middlePoints.count {
            let (randomX, randomY) = generateRandomXY()
            let (newDirectionPoint1, newDirectionPoint2) = generateDirectionPoints(randomX: randomX, randomY: randomY)
            let newBaseY = generateBaseY()
            
            moveControlPoint(to: CGPoint(x: randomX, y: randomY), direction1: newDirectionPoint1, direction2: newDirectionPoint2, baseY: newBaseY, withAnimationDuration: 2, index: i)
        }
    }
    
    private func generateRandomXY() -> (CGFloat, CGFloat) {
        let minX = bounds.minX
        let maxX = bounds.maxX
        let midY = bounds.midY
        let randomX = CGFloat.random(in: (minX + 8)...(maxX - 8))
        let height = bounds.height
        let maxYVariation = height * 0.2
        let yOffset = (maxYVariation / 2) * volume
        let randomY = CGFloat.random(in: (midY - yOffset)...(midY + yOffset))
        return (randomX, randomY)
    }
    
    private func generateDirectionPoints(randomX: CGFloat, randomY: CGFloat) -> (CGPoint, CGPoint) {
        var angle = CGFloat.random(in: 0...360) * .pi / 180
        while cos(angle) > 0.5 || cos(angle) < -0.5 {
            angle = CGFloat.random(in: 0...360) * .pi / 180
        }
        let distance = CGFloat.random(in: 1...5)
        let newDirectionPoint1 = CGPoint(x: randomX - abs(cos(angle)) * distance, y: randomY + sin(angle) * distance)
        let newDirectionPoint2 = CGPoint(x: randomX + abs(cos(angle)) * distance, y: randomY - sin(angle) * distance)
        return (newDirectionPoint1, newDirectionPoint2)
    }
    
    private func generateBaseY() -> CGFloat {
        let midY = bounds.midY
        let basePointAmplitude: CGFloat = 5.5
        let baseYVariation = CGFloat.random(in: -basePointAmplitude...basePointAmplitude)
        let newBaseY = midY + baseYVariation
        return newBaseY
    }
    
    func cleanup() {
        guard !isBeingDeallocated else { return }
        
        stopRandomMovement()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.isBeingDeallocated else { return }
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            self.shapeLayers.forEach { layers in
                layers.forEach { $0.removeFromSuperlayer() }
            }
            self.shapeLayers.removeAll()
            
            self.layer?.sublayers?.removeAll()
            self.layer?.filters = nil
            
            CATransaction.commit()
        }
    }
    
    deinit {
        isBeingDeallocated = true
        
        if Thread.isMainThread {
            cleanup()
        } else {
            DispatchQueue.main.sync { [weak self] in
                self?.cleanup()
            }
        }
    }
}
