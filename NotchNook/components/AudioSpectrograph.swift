//
//  AudioSpectrograph.swift
//  kepler notes
//
//  Created by Ethan Bills on 3/16/24.
//

import SwiftUI
import Combine

private let barsCount: CGFloat = 3

struct AudioSpectrograph: View, Equatable {
    static func == (lhs: AudioSpectrograph, rhs: AudioSpectrograph) -> Bool {
        lhs.color == rhs.color && lhs.playing == rhs.playing && lhs.volume == rhs.volume
    }
    
    var playing: Bool
    var volume: CGFloat = 1
    var color: Color = .white
    let minHeight: Double = 5
    let maxHeight: Double = 15
    let barsSpacing: Double = 1.5
    let barsThickness: Double = 2
    
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    @State private var barHeights = [CGFloat](repeating: 0, count: Int(barsCount)).map { _ in CGFloat.random(in: 5...15) }
    
    var body: some View {
        let volumeInterpolate = interpolatorBuilder([0, 1], value: volume)
        let volumeModifier = (volume * max(1, volumeInterpolate([3, 0], false)))
        HStack(spacing: barsSpacing) {
            ForEach(barHeights.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .frame(width: barsThickness, height: max(3, barHeights[index] * volumeModifier))
                    .foregroundColor(color)
                    .animation(.easeInOut(duration: 0.25), value: barHeights[index])
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 1)) // Adjust padding to create spacing effect
        }
        .frame(width: maxHeight * 1.5, height: maxHeight * 1.5)
        .animation(.spring, value: volume)
        .onReceive(timer) { _ in
            withAnimation {
                barHeights = playing ? barHeights.map { _ in CGFloat.random(in: minHeight...maxHeight) } : [3, 3, 3]
            }
        }
    }
}


//import SwiftUI
//import AVFoundation
//
//struct AudioSpectrograph: View {
//    var color: Color = .white
//    @State private var barHeights = [CGFloat](repeating: 0, count: 3)
//
//    private var audioEngine = AVAudioEngine()
//    private var inputNode: AVAudioInputNode { audioEngine.inputNode }
//    private let sampleRate: Float = 44100.0 // Common sample rate
//
//    var body: some View {
//        HStack(spacing: 1.5) {
//            ForEach(barHeights.indices, id: \.self) { index in
//                RoundedRectangle(cornerRadius: 1)
//                    .frame(width: 2, height: barHeights[index])
//                    .foregroundColor(color)
//                    .animation(.easeInOut, value: barHeights[index])
//            }
//        }
//        .onAppear {
//            startAudioEngine()
//        }
//        .onDisappear {
//            audioEngine.stop()
//        }
//    }
//
//    func startAudioEngine() {
//        let inputFormat = inputNode.outputFormat(forBus: 0)
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, _ in
//            let frameCount = buffer.frameLength
//            let channelData = buffer.floatChannelData![0]
//
//            var rmsLow: Float = 0
//            var rmsMid: Float = 0
//            var rmsHigh: Float = 0
//            let range = Int(frameCount) / 3
//            
//            // Calculate RMS for 3 frequency bands
//            for i in 0..<range {
//                rmsLow += channelData[i] * channelData[i]
//                rmsMid += channelData[i + range] * channelData[i + range]
//                rmsHigh += channelData[i + 2 * range] * channelData[i + 2 * range]
//            }
//            rmsLow = sqrt(rmsLow / Float(range))
//            rmsMid = sqrt(rmsMid / Float(range))
//            rmsHigh = sqrt(rmsHigh / Float(range))
//            
//            DispatchQueue.main.async {
//                self.barHeights[0] = CGFloat(rmsLow * 500)   // Scale factor for visual representation
//                self.barHeights[1] = CGFloat(rmsMid * 500)
//                self.barHeights[2] = CGFloat(rmsHigh * 500)
//            }
//        }
//
//        do {
//            try audioEngine.start()
//        } catch {
//            print("Could not start audio engine: \(error)")
//        }
//    }
//}
