//
//  AudioSpectrographView.swift
//  kepler notes
//
//  Created by Ethan Bills on 3/16/24.
//

import Cocoa
import QuartzCore
import SwiftUI

struct AudioSpectrographView: NSViewRepresentable {
    var isPlaying: Bool
    var volume: CGFloat
    var color: Color
        
    func makeNSView(context: Context) -> AudioSpectrographNSView {
        let nsView = AudioSpectrographNSView(frame: .zero)
        updateNSView(nsView, context: context)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak nsView] in
            nsView?.updateBarHeights()
        }
        return nsView
    }
    
    func updateNSView(_ nsView: AudioSpectrographNSView, context: Context) {
        if nsView.isPlaying != isPlaying { nsView.isPlaying = isPlaying }
        if nsView.volume != volume { nsView.volume = volume }
        let newColor = NSColor(color)
        if nsView.color != newColor { nsView.color = newColor }
    }
    
    static func dismantleNSView(_ nsView: AudioSpectrographNSView, coordinator: ()) {
        nsView.cleanup()
    }
}

class AudioSpectrographNSView: NSView {
    private let id = "spectograph-\(UUID().uuidString)"
    private let barsCount = 3
    private let minHeight: CGFloat = 2
    private let maxHeight: CGFloat = 15
    private let barsSpacing: CGFloat = 1.5
    private let barsThickness: CGFloat = 2
    
    private var barLayers: [CAShapeLayer] = []
    private var displayLinkHandler: DisplayLinkHandler?
    private var targetHeights: [CGFloat] = []
    private var currentHeights: [CGFloat] = []
    private var boundsWidth: CGFloat = 0
    private var animating = false
    private var isAnimatingBackTimer: Timer?
    
    private var isBeingDeallocated = false
    
    var isPlaying: Bool = false {
        didSet {
            if isPlaying {
                TimersManager.shared.removeTimer(id)
                startAnimation()
            } else {
                TimersManager.shared.addTimer(id, delay: 0.5) { _ in
                    self.stopAnimation()
                }
            }
        }
    }
    
    var volume: CGFloat = 1 {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateBarHeights()
            }
        }
    }
    
    var color: NSColor = .nonShockingWhite {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.barLayers.forEach { $0.fillColor = self.color.cgColor }
            }
        }
    }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        setupLayers()
        setupDisplayLink()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
        setupDisplayLink()
    }
    
    private func setupLayers() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.wantsLayer = true
            self.layer = CALayer()
            self.layer?.drawsAsynchronously = true
            self.layer?.isOpaque = true
            
            for _ in 0..<self.barsCount {
                let barLayer = CAShapeLayer()
                barLayer.drawsAsynchronously = true
                barLayer.isOpaque = true
                barLayer.fillColor = self.color.cgColor
                self.layer?.addSublayer(barLayer)
                self.barLayers.append(barLayer)
                self.targetHeights.append(self.minHeight)
                self.currentHeights.append(self.minHeight)
            }
            self.updateAnimation()
        }
    }
    
    private func setupDisplayLink() {
        displayLinkHandler = DisplayLinkHandler(target: self, fps: 60) { [weak self] in
            self?.updateAnimation()
        }
    }
    
    private func startAnimation() {
        displayLinkHandler?.start()
        self.animating = true
    }
    
    private func stopAnimation() {
        displayLinkHandler?.stop()
        animating = false
        resetBars()
    }
    
    private func resetBars() {
        for i in 0..<barsCount {
            if i < targetHeights.count, i < currentHeights.count {
                targetHeights[i] = minHeight
                currentHeights[i] = minHeight
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.updateBarHeights()
        }
    }
    
    func updateAnimation() {
        self.updateTargetHeights()
        self.interpolateHeights()
        self.updateBarHeights()
    }
    
    private func updateTargetHeights() {
        for i in 0..<barsCount {
            if abs(currentHeights[i] - targetHeights[i]) < 1 {
                targetHeights[i] = !isPlaying ? minHeight : CGFloat(Int.random(in: Int(minHeight)...Int(maxHeight)))
            }
        }
    }
    
    private func interpolateHeights() {
        let interpolationStep: CGFloat = 0.05 // Adjust interpolation speed
        for i in 0..<barsCount {
            let newHeight = currentHeights[i] + ((targetHeights[i] - currentHeights[i]) * interpolationStep)
            currentHeights[i] = abs(currentHeights[i] - newHeight) < 0.02 ? targetHeights[i] : newHeight
        }
    }
    
    func updateBarHeights() {
        // Ensure this method is called on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.updateBarHeights()
            }
            return
        }
        
        let volumeInterpolate = interpolatorBuilder([0.01, 1], value: volume)
        let volumeModifier = volume == 0 ? 0 : volumeInterpolate([0.25, 1], false)
        
        let totalWidth = CGFloat(barsCount) * (barsThickness + barsSpacing) - barsSpacing
        let startX = (bounds.width - totalWidth) / 2
        
        for i in 0..<min(barsCount, barLayers.count) {
            let height = max(minHeight, currentHeights[i] * volumeModifier)
            let x = startX + CGFloat(i) * (barsThickness + barsSpacing)
            
            let barRect = CGRect(x: x, y: (bounds.height - height) / 2, width: barsThickness, height: height)
            
            let path = NSBezierPath(roundedRect: barRect, xRadius: barsThickness / 2, yRadius: barsThickness / 2)
            
            barLayers[i].path = path.cgPath
        }
        
        let pausedAndSettled = !isPlaying && currentHeights.reduce(true) { partialResult, height in
            return partialResult && height == minHeight
        }
        
        if pausedAndSettled && animating {
            stopAnimation()
        }
    }
    
    private func interpolatorBuilder(_ range: [CGFloat], value: CGFloat) -> ([CGFloat], Bool) -> CGFloat {
        return { interpolationRange, _ in
            let inputMin = range[0]
            let inputMax = range[1]
            let outputMin = interpolationRange[0]
            let outputMax = interpolationRange[1]
            
            let inputRange = inputMax - inputMin
            let outputRange = outputMax - outputMin
            
            let normalizedValue = (value - inputMin) / inputRange
            return outputMin + (normalizedValue * outputRange)
        }
    }
    
    func cleanup() {
        guard !isBeingDeallocated else { return }
        
        stopAnimation()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.isBeingDeallocated else { return }
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            self.barLayers.forEach { $0.removeFromSuperlayer() }
            self.barLayers.removeAll()
            
            self.layer?.sublayers?.removeAll()
            
            CATransaction.commit()
        }
    }
    
    deinit {
        isBeingDeallocated = true
        TimersManager.shared.removeTimer(id)
        displayLinkHandler = nil
        
        // Perform synchronous cleanup on the main thread
        if Thread.isMainThread {
            cleanup()
        } else {
            DispatchQueue.main.sync { [weak self] in
                self?.cleanup()
            }
        }
    }

}
