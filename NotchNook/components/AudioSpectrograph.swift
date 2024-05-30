//
//  AudioSpectrograph.swift
//  kepler notes
//
//  Created by Ethan Bills on 3/16/24.
//

import SpriteKit
import SwiftUI
import Combine

private let barsCount: Int = 3

//struct AudioSpectrograph: View {
//    var playing: Bool
//    var volume: CGFloat = 1
//    var color: Color = .white
//    let minHeight: CGFloat = 5
//    let maxHeight: CGFloat = 15
//    let barsSpacing: CGFloat = 1.5
//    let barsThickness: CGFloat = 2
//    
//    var body: some View {
//        TimelineView(.periodic(from: .now, by: 0.25)) { context in
//            let volumeInterpolate = interpolatorBuilder([0, 1], value: volume)
//            let volumeModifier = (volume * max(1, volumeInterpolate([3, 0], false)))
//            
//            let barHeights: [CGFloat] = playing ? (0..<barsCount).map { _ in CGFloat.random(in: minHeight...maxHeight) } : Array(repeating: 3, count: barsCount)
//            
//            HStack(spacing: barsSpacing) {
//                ForEach(barHeights.indices, id: \.self) { index in
//                    let height = max(3, barHeights[index] * volumeModifier)
//                    RoundedRectangle(cornerRadius: 1)
//                        .frame(width: barsThickness, height: height)
//                        .foregroundColor(color)
//                        .animation(.default, value: [volume, height])
//                }
//                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 1)) // Adjust padding to create spacing effect
//            }
//            .frame(width: maxHeight * 1.5, height: maxHeight * 1.5)
//        }
//    }
//}

class AudioSpectrographScene: SKScene {
    var bars: [SKSpriteNode] = []
    var playing: Bool = false {
        didSet {
            if playing {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    var volume: CGFloat = 0.0
    var color: NSColor = .white

    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        createBars()
    }
    
    func removeBars() {
        bars.forEach { bar in
            bar.removeFromParent()
        }
        bars = []
    }

    func createBars() {
        removeBars()
        
        let numberOfBars = 3
        let barWidth: CGFloat = 2
        let spacing: CGFloat = 2
        let startX = (self.size.width - CGFloat(numberOfBars) * (barWidth + spacing) + spacing) / 2

        for i in 0..<numberOfBars {
            let bar = SKSpriteNode(color: color, size: CGSize(width: barWidth, height: 3))
            bar.position = CGPoint(x: startX + CGFloat(i) * (barWidth + spacing), y: self.size.height / 2)
            bar.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            bars.append(bar)
            self.addChild(bar)
        }
    }

    func startAnimation() {
        let updateAction = SKAction.run { [weak self] in
            self?.updateHeights()
        }
        let waitAction = SKAction.wait(forDuration: 0.2) // Increased interval
        let sequenceAction = SKAction.sequence([updateAction, waitAction])
        let repeatAction = SKAction.repeatForever(sequenceAction)
        self.run(repeatAction, withKey: "updateHeights")
    }

    func stopAnimation() {
        self.removeAction(forKey: "updateHeights")
        updateHeights()
    }

    func updateHeights() {
        let volumeInterpolate = interpolatorBuilder([0, 1], value: volume)
        let volumeModifier = (volume * max(1, volumeInterpolate([5, 1], false)))
        for bar in bars {
            let newHeight = playing ? CGFloat.random(in: 5...15) * volumeModifier : 2
            let resizeAction = SKAction.resize(toHeight: max(2, newHeight), duration: 0.2) // Slightly longer duration
            resizeAction.timingMode = .easeInEaseOut
            bar.run(resizeAction)
        }
    }
}

struct AudioSpectrograph: View {
    var playing: Bool
    var volume: CGFloat
    var color: Color

    var body: some View {
        SpriteView(scene: scene)
            .frame(width: 22, height: 22) // Adjust size as needed
            .onAppear {
                scene.scaleMode = .resizeFill
                scene.size = CGSize(width: 50, height: 50)
            }
            .onChange(of: playing, initial: true) { _, newValue in
                scene.playing = newValue
            }
            .onChange(of: volume, initial: true) { _, newValue in
                scene.volume = newValue
            }
            .onChange(of: color, initial: true) { _, newValue in
                scene.color = NSColor(newValue)
                scene.bars.forEach { $0.color = scene.color }
            }
    }

    @State private var scene = AudioSpectrographScene()
}
