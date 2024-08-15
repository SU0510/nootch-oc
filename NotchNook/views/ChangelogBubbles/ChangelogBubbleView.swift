//
//  ChangelogBubbleView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 31/07/24.
//

import SwiftUI
import DynamicColor

struct ChangelogBubbleView: View, Equatable {
    static func == (lhs: ChangelogBubbleView, rhs: ChangelogBubbleView) -> Bool {
        true
    }
    
    @State private var isRotating = false
    
    var body: some View {
        let rotationDegrees: Double = 15
        HStack {
//            Image(.starChangelog)
//                .resizable()
//                .frame(20)
        }
        .frame(32)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .circular)
                    .fill(
                        LinearGradient(
                            colors: [Color(hexString: "EFF4BB"),Color(hexString: "EBF48B")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .shadow(.drop(color: .black.opacity(0.75), radius: 16, y: 8))
                    )
                
                RoundedRectangle(cornerRadius: 20, style: .circular)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hexString: "FFFFFF").opacity(0),Color(hexString: "ABABAB")],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .padding(0.75)
                    .blendMode(.plusDarker)
                
                RoundedRectangle(cornerRadius: 20, style: .circular)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hexString: "3B3B3B"),Color(hexString: "000000")],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .padding(0.75)
                    .blendMode(.plusLighter)
            }
        }
        .rotation3DEffect(.degrees(isRotating ? rotationDegrees : -rotationDegrees), axis: (x: 1, y: 0, z:  0))
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isRotating)
        .rotation3DEffect(.degrees(isRotating ? rotationDegrees / 2 : -rotationDegrees / 2), axis: (x: 0, y: 0, z: 1))
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(1.0), value: isRotating)
        .onAppear {
            isRotating.toggle()
        }
    }
}
