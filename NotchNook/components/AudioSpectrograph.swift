//
//  AudioSpectrograph.swift
//  kepler notes
//
//  Created by Ethan Bills on 3/16/24.
//

import SpriteKit
import SwiftUI
import Combine
import AppKit

private let barsCount: Int = 3

struct AudioSpectrograph: View {
    var playing: Bool
    var volume: CGFloat = 1
    var color: Color = .white
    let minHeight: CGFloat = 5
    let maxHeight: CGFloat = 15
    let barsSpacing: CGFloat = 1.5
    let barsThickness: CGFloat = 2
    //    @State private var phases = (1...100).map { _ in (1...3).map { _ in CGFloat.random(in: 5...15) } }
    var body: some View {
        let volumeInterpolate = interpolatorBuilder([0.01, 1], value: volume)
        let volumeModifier = volume == 0 ? 0 : volumeInterpolate([0.25, 1], false)
        VStack {
            TimelineView(.animation(minimumInterval: 0.25)) { context in
                let heights = (1...3).map { _ in CGFloat.random(in: 5...15) }
                HStack(spacing: barsSpacing) {
                    Capsule().frame(width: 2, height: !playing ? 2 : max(2, heights[0] * volumeModifier))
                    Capsule().frame(width: 2, height: !playing ? 2 : max(2, heights[1] * volumeModifier))
                    Capsule().frame(width: 2, height: !playing ? 2 : max(2, heights[2] * volumeModifier))
                }
                .animation(.easeIn(duration: 0.25), value: heights)
            }
        }
        .foregroundColor(color)
        .frame(width: maxHeight * 1.5, height: maxHeight * 1.5)
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
