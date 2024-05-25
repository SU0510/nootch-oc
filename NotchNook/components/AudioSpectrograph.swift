//
//  AudioSpectrograph.swift
//  kepler notes
//
//  Created by Ethan Bills on 3/16/24.
//

import SwiftUI

struct AudioSpectrograph: View, Equatable {
    static func == (lhs: AudioSpectrograph, rhs: AudioSpectrograph) -> Bool {
        lhs.color == rhs.color
    }
    
    var color: Color = .white
    let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    @State private var barHeights = [CGFloat](repeating: 0, count: 3).map { _ in CGFloat.random(in: 5...15) }
    
    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(barHeights.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .frame(width: 2, height: barHeights[index])
                    .foregroundColor(color)
                    .animation(.easeInOut(duration: 0.25), value: barHeights[index])
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 1)) // Adjust padding to create spacing effect
        }
        .onReceive(timer) { _ in
            withAnimation {
                // Randomize the bar heights to simulate live audio input
                barHeights = barHeights.map { _ in CGFloat.random(in: 5...15) }
            }
        }
    }
}
