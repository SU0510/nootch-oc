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
    private let minHeight: CGFloat = 1
    private let maxHeight: CGFloat = 23
    private let barsSpacing: CGFloat = 1.5
    private let barsThickness: CGFloat = 2
    
    private var barLayers: [CAShapeLayer] = []
    private var displayLink: CVDisplayLink?
    private var targetHeights: [CGFloat] = []
    private var currentHeights: [CGFloat] = []
    
    var playing: Bool = false {
        didSet {
            if playing {
                startAnimation()
            } else {
                stopAnimation()
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
        
        for _ in 0..<barsCount {
            let leftBarLayer = CAShapeLayer()
            let rightBarLayer = CAShapeLayer()
            leftBarLayer.fillColor = color.cgColor
            rightBarLayer.fillColor = color.cgColor
            layer?.addSublayer(leftBarLayer)
            layer?.addSublayer(rightBarLayer)
            barLayers.append(contentsOf: [leftBarLayer, rightBarLayer])
            targetHeights.append(minHeight)
            currentHeights.append(minHeight)
        }
        updateBarHeights()
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
        CVDisplayLinkStart(displayLink)
    }
    
    private func stopAnimation() {
        guard let displayLink = displayLink else { return }
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
            if abs(currentHeights[i] - targetHeights[i]) < 0.1 || Bool.random() {
                targetHeights[i] = CGFloat.random(in: minHeight...maxHeight)
            }
        }
    }
    
    private func interpolateHeights() {
        let interpolationStep: CGFloat = 0.05
        for i in 0..<barsCount {
            currentHeights[i] += (targetHeights[i] - currentHeights[i]) * interpolationStep
        }
    }
    
    private func updateBarHeights() {
        let volumeInterpolate = interpolatorBuilder([0.01, 1], value: volume)
        let volumeModifier = volume == 0 ? 0 : volumeInterpolate([0.25, 1], false)
        
        let totalWidth = CGFloat(barsCount) * (barsThickness + barsSpacing) - barsSpacing
        let startX = (bounds.width - totalWidth) / 2
        
        for i in 0..<barsCount {
            let height = playing ? max(2, currentHeights[i] * volumeModifier) : 2
            let x = startX + CGFloat(i) * (barsThickness + barsSpacing)
            
            let leftBarRect = CGRect(x: x, y: (bounds.height - height) / 2, width: barsThickness, height: height)
            let rightBarRect = CGRect(x: bounds.width - x - barsThickness, y: (bounds.height - height) / 2, width: barsThickness, height: height)
            
            let leftPath = NSBezierPath(roundedRect: leftBarRect, xRadius: barsThickness / 2, yRadius: barsThickness / 2)
            let rightPath = NSBezierPath(roundedRect: rightBarRect, xRadius: barsThickness / 2, yRadius: barsThickness / 2)
            
            barLayers[i * 2].path = leftPath.cgPath
            barLayers[i * 2 + 1].path = rightPath.cgPath
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
        let view = AudioSpectrographView(frame: .zero)
        updateNSView(view, context: context)
        return view
    }
    
    func updateNSView(_ nsView: AudioSpectrographView, context: Context) {
        nsView.playing = playing
        nsView.volume = volume
        nsView.color = NSColor(color)
    }
}

// Custom NSView for displaying the audio spectrograph
//class AudioSpectrographView: NSView {
//    var playing: Bool = false {
//        didSet {
//            if playing {
//                startTimer()
//            } else {
//                stopTimer()
//            }
//        }
//    }
//    var volume: CGFloat = 1.0
//    var color: NSColor = .white
//    private var barHeights: [CGFloat] = []
//    private var timer: Timer?
//
//    override init(frame frameRect: NSRect) {
//        super.init(frame: frameRect)
//        initializeBarHeights()
//        self.wantsLayer = true  // Ensure the view uses layer-backed rendering.
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        initializeBarHeights()
//        self.wantsLayer = true
//    }
//    
//    private func initializeBarHeights() {
//        let numBars = Int(frame.width / (2 + 1.5))
//        barHeights = Array(repeating: 5, count: numBars)
//    }
//
//    private func startTimer() {
//        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(updateBarHeights), userInfo: nil, repeats: true)
//    }
//
//    private func stopTimer() {
//        timer?.invalidate()
//        timer = nil
//    }
//
//    @objc private func updateBarHeights() {
//        for i in 0..<barHeights.count {
//            barHeights[i] = CGFloat.random(in: 5...15) * volume
//        }
//        DispatchQueue.main.async {
//            self.needsDisplay = true
//        }
//    }
//
//    override func draw(_ dirtyRect: NSRect) {
//        guard let context = NSGraphicsContext.current?.cgContext else { return }
//        context.setFillColor(color.cgColor)
//        
//        let barWidth: CGFloat = 2
//        let barSpacing: CGFloat = 1.5
//        
//        for i in 0..<barHeights.count {
//            let height = playing ? barHeights[i] : 5
//            let xPosition = CGFloat(i) * (barWidth + barSpacing)
//            context.fill(CGRect(x: xPosition, y: (bounds.height - height) / 2, width: barWidth, height: height))
//        }
//    }
//}
//
//// NSViewRepresentable wrapper for AudioSpectrographView
//struct AudioSpectrographRepresentable: NSViewRepresentable {
//    var playing: Bool
//    var volume: CGFloat
//    var color: Color
//
//    func makeNSView(context: Context) -> AudioSpectrographView {
//        let view = AudioSpectrographView(frame: CGRect(x: 0, y: 0, width: 200, height: 50)) // Set a default size
//        view.playing = playing
//        view.volume = volume
//        view.color = NSColor(color)
//        return view
//    }
//
//    func updateNSView(_ nsView: AudioSpectrographView, context: Context) {
//        nsView.playing = playing
//        nsView.volume = volume
//        nsView.color = NSColor(color)
//    }
//}

//import SwiftUI
//import AppKit

//struct AudioSpectrograph: NSViewRepresentable {
//    var playing: Bool
//    var volume: Double
//    var color: Color
//
//    func makeNSView(context: Context) -> CustomBarView {
//        let view = CustomBarView()
//        view.barColor = NSColor(color)
//        return view
//    }
//
//    func updateNSView(_ nsView: CustomBarView, context: Context) {
//        nsView.barColor = NSColor(color)
//        nsView.playing = playing
//    }
//}
//
//class CustomBarView: NSView {
//    var barColor: NSColor = .black {
//        didSet {
//            needsDisplay = true
//        }
//    }
//
//    var playing: Bool = true {
//        didSet {
//            if playing {
//                startAnimating()
//            } else {
//                stopAnimating()
//            }
//        }
//    }
//
//    private var heights: [CGFloat] = [2, 2, 2]
//    private var timer: Timer?
//
//    override init(frame frameRect: NSRect) {
//        super.init(frame: frameRect)
//        startAnimating()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func draw(_ dirtyRect: NSRect) {
//        super.draw(dirtyRect)
//
//        guard let context = NSGraphicsContext.current?.cgContext else { return }
//
//        context.setFillColor(barColor.cgColor)
//
//        let barWidth: CGFloat = 2
//        let spacing: CGFloat = 1
//
//        for i in 0..<3 {
//            let x = CGFloat(i) * (barWidth + spacing)
//            let rect = CGRect(x: x, y: 0, width: barWidth, height: heights[i])
//            context.fill(rect)
//        }
//    }
//
//    private func startAnimating() {
//        timer?.invalidate()
//        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
//            guard let self = self else { return }
//            self.heights = (0..<3).map { _ in CGFloat.random(in: 5...15) }
//            self.needsDisplay = true
//        }
//    }
//
//    private func stopAnimating() {
//        timer?.invalidate()
//        heights = [2, 2, 2]
//        needsDisplay = true
//    }
//}
