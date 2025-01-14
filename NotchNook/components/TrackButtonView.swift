//
//  NextTrackButtonView.swift
//  NotchNook
//
//  Created by Lori Montenegro on 13/01/25.
//

import SwiftUI

struct TrackButtonView: View {
    enum Direction {
        case next, previous
    }
    
    let direction: Direction
    var iconSize: Double = 10
    
    @State private var hovering = false
    @State private var isAnimating = false
    @State private var animationCount = 0
    
    var body: some View {
        Button(action: {
            animationCount += 1
            direction == .next ? MediaControls.shared.goToNextTrack() : MediaControls.shared.goToPreviousTrack()
        }) {
            HStack(spacing: -6) {
                // Left triangle (appears growing during animation)
                RoundedTriangle()
                    .fill(.white.opacity(isAnimating ? 1 : 0))
                    .frame(width: iconSize, height: iconSize)
                    .scaleEffect(isAnimating ? 1 : 0.1)
                    .offset(x: isAnimating ? 7 : 0)
                    .opacity(isAnimating ? 1 : 0)
                
                // Centered pair of triangles
                HStack(spacing: -3) {
                    // Middle triangle (slightly scales up during animation)
                    RoundedTriangle()
                        .fill(.nonShockingWhite.opacity(hovering ? 1 : 0.85))
                        .frame(width: iconSize, height: iconSize)
                        .scaleEffect(isAnimating ? 1 : 0.95)
                        .offset(x: isAnimating ? 7 : 0)
                    
                    // Right triangle (shrinks and fades out during animation)
                    RoundedTriangle()
                        .fill(.nonShockingWhite.opacity(hovering ? 1 : 0.85))
                        .frame(width: iconSize, height: iconSize)
                        .scaleEffect(isAnimating ? 0.01 : 1)
                        .offset(x: isAnimating ? 7 : 0)
                        .opacity(isAnimating ? 0 : 1)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(width: 27, height: 27)
            .background(Color.selected.opacity(hovering ? 1 : 0), in: Circle())
            .contentShape(Circle())
            .scaleEffect(x: direction == .next ? 1 : -1, y: 1)
        }
        .buttonStyle(ShrinkOnClick())
        .onHover { newHovering in
            withAnimation(.easeOut(duration: 0.2)) { hovering = newHovering }
        }
        .onChange(of: animationCount) {
            withAnimation(.spring(duration: 0.4, bounce: 0.4)) {
                isAnimating = true
            } completion: {
                isAnimating = false
            }
        }
    }
}
