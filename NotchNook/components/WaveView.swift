//
//  WaveView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 06/07/24.
//

import SwiftUI
import Cocoa
import QuartzCore

class GradientBlobView: NSView {
    private var displayLink: CVDisplayLink?
    private var startTime: CFTimeInterval?
    private var circleCount = 5
    private var colors: [CGColor] = [
        NSColor.systemRed.cgColor,
        NSColor.systemBlue.cgColor,
        NSColor.systemGreen.cgColor,
        NSColor.systemYellow.cgColor,
        NSColor.systemPurple.cgColor,
        NSColor.systemOrange.cgColor
    ]

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupDisplayLink()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDisplayLink()
    }
    
    deinit {
        CVDisplayLinkStop(displayLink!)
    }
    
    private func setupDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputCallback(displayLink!, { (_, _, _, _, _, userInfo) -> CVReturn in
            let view = Unmanaged<GradientBlobView>.fromOpaque(userInfo!).takeUnretainedValue()
            DispatchQueue.main.async {
                view.needsDisplay = true
            }
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())
        CVDisplayLinkStart(displayLink!)
        startTime = CACurrentMediaTime()
    }
    
    // Modify the draw function to ensure the context image is not nil before creating CIImage
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.clear(bounds)

        let currentTime = CACurrentMediaTime()
        let elapsedTime = currentTime - (startTime ?? currentTime)

        drawAnimatedCircles(in: context, time: elapsedTime)

        guard let cgImage = context.makeImage() else { return }
        let baseImage = CIImage(cgImage: cgImage)

        let blurFilter = CIFilter(name: "CIGaussianBlur")!
        blurFilter.setValue(baseImage, forKey: "inputRadius")
        blurFilter.setValue(20, forKey: kCIInputRadiusKey)

        let contextCI = CIContext(options: nil)
        guard let outputImage = blurFilter.outputImage, let cgimg = contextCI.createCGImage(outputImage, from: outputImage.extent) else { return }

        context.draw(cgimg, in: bounds)
    }
    
    private var circleCenters: [CGPoint] = []
    private var circleDirections: [CGPoint] = []
    private var circleColors: [CGColor] = []

    private func drawAnimatedCircles(in context: CGContext, time: CFTimeInterval) {
        let maxRadius = hypot(bounds.width, bounds.height) * 0.35
        let numCircles = 5

        if circleCenters.isEmpty {
            for _ in 0..<numCircles {
                let xPos = CGFloat(arc4random_uniform(UInt32(bounds.width)))
                let yPos = CGFloat(arc4random_uniform(UInt32(bounds.height)))
                circleCenters.append(CGPoint(x: xPos, y: yPos))
                circleDirections.append(CGPoint(x: CGFloat(drand48() - 0.5), y: CGFloat(drand48() - 0.5)))
                let color = NSColor(calibratedRed: CGFloat(drand48()),
                                    green: CGFloat(drand48()),
                                    blue: CGFloat(drand48()),
                                    alpha: 1.0).cgColor
                circleColors.append(color)
            }
        }

        for i in 0..<numCircles {
            circleCenters[i].x += circleDirections[i].x
            circleCenters[i].y += circleDirections[i].y

            if circleCenters[i].x < 0 || circleCenters[i].x > bounds.width {
                circleDirections[i].x *= -1
            }
            if circleCenters[i].y < 0 || circleCenters[i].y > bounds.height {
                circleDirections[i].y *= -1
            }

            context.setFillColor(circleColors[i])
            context.fillEllipse(in: CGRect(x: circleCenters[i].x - maxRadius, y: circleCenters[i].y - maxRadius, width: maxRadius * 2, height: maxRadius * 2))
        }
    }
}


struct WaveViewRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        return GradientBlobView(frame: .zero)
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update the view if needed
    }
}
