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

struct MiddlePoint {
    var control: CGPoint
    var direction1: CGPoint
    var direction2: CGPoint
}

class WobblyBezierView: NSView {
    var volume: Double = 1
    var color: NSColor = .white {
        didSet {
            shapeLayers.forEach { layers in
                layers.forEach { layer in
                    let i = CGFloat(try! Int(layer.name ?? "0")!)
                    layer.strokeColor = color.darkened(amount: i * 0.1).shaded(amount: i * 0.2).cgColor
                }
            }
        }
    }
    private var middlePoints: [MiddlePoint]
    private var movementTimer: Timer?
    private var blurTimer: Timer?
    private var blurFilter = CIFilter(name: "CIGaussianBlur")!
    
    private lazy var shapeLayers: [[CAShapeLayer]] = {
        var layers = [[CAShapeLayer]]()
        for i in 0..<middlePoints.count {
            var innerLayers = [CAShapeLayer]()
            for _ in 0..<2 {
                let layer = CAShapeLayer()
                layer.strokeColor = color.darkened(amount: CGFloat(i) * 0.2).cgColor
                layer.lineWidth = 1
                layer.fillColor = NSColor.clear.cgColor
                layer.name = "\(i)"
                //            layer.opacity = 1.0 - (Float(i) * 0.3)
                innerLayers.append(layer)
                layer.zPosition = CGFloat(middlePoints.count - i)
                self.layer?.addSublayer(layer)
            }
            layers.append(innerLayers)
        }
        return layers
    }()

    init(frame frameRect: NSRect, linesCount: Int = 3) {
        middlePoints = Array(repeating: MiddlePoint(control: .zero, direction1: .zero, direction2: .zero), count: linesCount)
        super.init(frame: frameRect)
        self.layer = CALayer()
        blurFilter.name = "blur"
        self.layer?.filters = [blurFilter]
        self.layer?.setValue(0, forKeyPath: "filters.blur.inputRadius")
        self.wantsLayer = true
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
        self.layer?.add(animation, forKey: nil)
    }

    func moveControlPoint(to newControlPoint: CGPoint, direction1 newDirectionPoint1: CGPoint, direction2 newDirectionPoint2: CGPoint, withAnimationDuration duration: TimeInterval, index: Int) {
        let innerLayers = shapeLayers[index]
        Array(innerLayers.enumerated()).forEach { i, layer in
            let animation = CABasicAnimation(keyPath: "path")
            animation.timingFunction = .init(name: .linear)
            animation.duration = duration
            animation.fromValue = layer.presentation()?.path
            
            animation.isRemovedOnCompletion = true
            
            let newPath = NSBezierPath()
            newPath.move(to: CGPoint(x: bounds.minX, y: bounds.midY))
            newPath.curve(to: CGPoint(x: bounds.maxX, y: bounds.midY + (i == 0 ? -3 : 3)), controlPoint1: newDirectionPoint1, controlPoint2: newDirectionPoint2)
            animation.toValue = newPath.cgPath
            
            layer.add(animation, forKey: "a")
            layer.path = newPath.cgPath
            
            middlePoints[index] = MiddlePoint(control: newControlPoint, direction1: newDirectionPoint1, direction2: newDirectionPoint2)
        }
    }
    
    func startRandomMovement() {
//        blurTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
//            guard let self = self else {
//                timer.invalidate()
//                return
//            }
//            
//            self.changeBlur(to: .random(in: 0...2))
//        }
        movementTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            for i in 0..<self.middlePoints.count {
                let minX = self.bounds.minX
                let maxX = self.bounds.maxX
                let midY = self.bounds.midY
                let randomX = CGFloat.random(in: (minX + 8)...(maxX - 8))
                let height = self.bounds.height
                let maxYVariation = height * 0.55
                let yOffset = (maxYVariation / 2) * volume
                let randomY = CGFloat.random(in: (midY - yOffset)...(midY + yOffset))

                var angle = CGFloat.random(in: 0...360) * .pi / 180
                while cos(angle) > 0.5 || cos(angle) < -0.5 {
                    angle = CGFloat.random(in: 0...360) * .pi / 180
                }

                let distance = CGFloat.random(in: 1...10)

                let newControlPoint = CGPoint(x: randomX, y: randomY)
                let newDirectionPoint1 = CGPoint(x: newControlPoint.x - abs(cos(angle)) * distance, y: newControlPoint.y + sin(angle) * distance)
                let newDirectionPoint2 = CGPoint(x: newControlPoint.x + abs(cos(angle)) * distance, y: newControlPoint.y - sin(angle) * distance)

//                self.changeBlur(to: .random(in: 0...2))
                self.moveControlPoint(to: newControlPoint, direction1: newDirectionPoint1, direction2: newDirectionPoint2, withAnimationDuration: 0.35, index: i)
            }
        }
    }
}


struct WaveViewRepresentable: NSViewRepresentable {
    var volume: Double = 1
    var color: Color
    func makeNSView(context: Context) -> WobblyBezierView {
        let view = WobblyBezierView(frame: .zero)
        view.startRandomMovement()
        return view
    }
    
    func updateNSView(_ nsView: WobblyBezierView, context: Context) {
        nsView.color = NSColor(color)
        nsView.volume = volume
        // Update the view if needed
    }
    
    func createShadowLayer() -> CALayer {
        let shadowLayer = CALayer()
        shadowLayer.shadowColor = NSColor.red.cgColor
        shadowLayer.shadowOffset = CGSize.zero
        shadowLayer.shadowRadius = 9.0
        shadowLayer.shadowOpacity = 1.0
        shadowLayer.backgroundColor = NSColor.clear.cgColor
        return shadowLayer
    }
}











