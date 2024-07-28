//
//  AudioSpectrograph.swift
//  kepler notes
//
//  Created by Ethan Bills on 3/16/24.
//

import Cocoa
import QuartzCore
import SwiftUI

class AudioSpectrographView: NSView {
    private let barsCount = 3
    private let minHeight: CGFloat = 2
    private let maxHeight: CGFloat = 15
    private let barsSpacing: CGFloat = 1.5
    private let barsThickness: CGFloat = 2
    
    private var barLayers: [CAShapeLayer] = []
    private var displayLink: CVDisplayLink?
    private var targetHeights: [CGFloat] = []
    private var currentHeights: [CGFloat] = []
    private var boundsWidth: CGFloat = 0
    private var animating = false
    
    var playing: Bool = false {
        didSet {
            if playing {
                startAnimation()
            }
        }
    }
    
    var volume: CGFloat = 1 {
        didSet {
            updateBarHeights()
        }
    }
    
    var color: NSColor = .white {
        didSet {
            barLayers.forEach { $0.fillColor = color.cgColor }
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
        self.wantsLayer = true
        self.layer = CALayer()
//        self.layer?.drawsAsynchronously = true
        self.layer?.isOpaque = true
        
        for _ in 0..<barsCount {
            let barLayer = CAShapeLayer()
            barLayer.drawsAsynchronously = true
            barLayer.isOpaque = true
            barLayer.fillColor = color.cgColor
            layer?.addSublayer(barLayer)
            barLayers.append(barLayer)
            targetHeights.append(minHeight)
            currentHeights.append(minHeight)
        }
        updateAnimation()
    }
    
    private func setupDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        guard let displayLink = displayLink else { return }
        
        let displayLinkOutputCallback: CVDisplayLinkOutputCallback = { (displayLink, _, _, _, _, displayLinkContext) -> CVReturn in
            let audioSpectrographView = unsafeBitCast(displayLinkContext, to: AudioSpectrographView.self)
            audioSpectrographView.updateAnimation()
            return kCVReturnSuccess
        }
        
        let userInfo = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        CVDisplayLinkSetOutputCallback(displayLink, displayLinkOutputCallback, userInfo)
    }
    
    private func startAnimation() {
        guard let displayLink = displayLink else { return }
        self.animating = true
        CVDisplayLinkStart(displayLink)
    }
    
    private func stopAnimation() {
        guard let displayLink = displayLink else { return }
        animating = false
        CVDisplayLinkStop(displayLink)
        resetBars()
    }
    
    private func resetBars() {
        for i in 0..<barsCount {
            targetHeights[i] = minHeight
            currentHeights[i] = minHeight
        }
        updateBarHeights()
    }
    
    private func updateAnimation() {
        DispatchQueue.main.async {
            self.updateTargetHeights()
            self.interpolateHeights()
            self.updateBarHeights()
        }
    }
    
    private func updateTargetHeights() {
        for i in 0..<barsCount {
            if abs(currentHeights[i] - targetHeights[i]) < 1 {
                targetHeights[i] = !playing ? minHeight : CGFloat(Int.random(in: Int(minHeight)...Int(maxHeight)))
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
    
    private func updateBarHeights() {
        let volumeInterpolate = interpolatorBuilder([0.01, 1], value: volume)
        let volumeModifier = volume == 0 ? 0 : volumeInterpolate([0.25, 1], false)
        
        let totalWidth = CGFloat(barsCount) * (barsThickness + barsSpacing) - barsSpacing
        let startX = (bounds.width - totalWidth) / 2
        
        for i in 0..<barsCount {
            let height = max(minHeight, currentHeights[i] * volumeModifier)
            let x = startX + CGFloat(i) * (barsThickness + barsSpacing)
            
            let barRect = CGRect(x: x, y: (bounds.height - height) / 2, width: barsThickness, height: height)
            
            let path = NSBezierPath(roundedRect: barRect, xRadius: barsThickness / 2, yRadius: barsThickness / 2)
            
            barLayers[i].path = path.cgPath
        }
        
        let pausedAndSettled = !playing && currentHeights.reduce(true) { partialResult, height in
            return partialResult && height == minHeight
        }
        
        if pausedAndSettled && animating {
            stopAnimation()
            return
        }
    }
    
    deinit {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
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
}

struct AudioSpectrographRepresentable: NSViewRepresentable {
    var playing: Bool
    var volume: CGFloat
    var color: Color
    
    func makeNSView(context: Context) -> AudioSpectrographView {
        let nsView = AudioSpectrographView(frame: .zero)
        updateNSView(nsView, context: context)
        return nsView
    }
    
    func updateNSView(_ nsView: AudioSpectrographView, context: Context) {
        if nsView.playing != playing { nsView.playing = playing }
        if nsView.volume != volume { nsView.volume = volume }
        let newColor = NSColor(color)
        if nsView.color != newColor { nsView.color = newColor }
    }
}
