//
//  TheMarquee.swift
//  NotchNook
//
//  Created by Igor Marcossi on 16/06/24.
//

import SwiftUI

struct TheMarquee<C: View>: View {
    var width: Double
    var secsBeforeLooping: Double = 0
    var speedPtsPerSec: Double = 30
    var marqueeAlignment: Alignment = .leading
    var nonMovingAlignment: Alignment = .center
    var spacingBetweenElements: Double = 8
    var horizontalPadding: Double = 8
    var fadeLength: Double = 8
    @ViewBuilder var content: () -> C
    @State private var contentSize: CGSize = .zero
    @State private var containerSize: CGSize = .zero
    @State private var offset: Double = 0
    @State private var animating = false
        
    var measured: Bool { contentSize != .zero && containerSize != .zero }
    var shouldMove: Bool { measured && contentSize.width > containerSize.width }
    
    func startAnimation() {
        if !measured || !shouldMove || animating { return }
        animating = true
        animLoop()
    }
    
    func animLoop() {
        if !animating { return }
        let offsetAmount = contentSize.width + spacingBetweenElements
        let duration = offsetAmount / speedPtsPerSec
        withAnimation(.linear(duration: duration)) {
            offset = -offsetAmount
        } completion: {
            offset = 0
            doAfter(secsBeforeLooping) {
                if self.animating {
                    self.animLoop()
                }
            }
        }
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: spacingBetweenElements) {
                content()
                    .measure($contentSize)
                
                if measured && shouldMove {
                    content()
                }
            }
            .padding(.leading, shouldMove ? max(fadeLength, horizontalPadding) : 0)
            .frame(minWidth: width, alignment: nonMovingAlignment)
            .offset(x: offset)
        }
        .scrollDisabled(true)
        .frame(width: width)
        .fadeOnEdges(axis: .horizontal, topLeadingFadeLength: fadeLength, bottomTrailingFadeLength: fadeLength, disable: !shouldMove || fadeLength == 0)
        .measure($containerSize)
        .compositingGroup()
        .opacity(measured ? 1 : 0)
        .onChange(of: containerSize) { _, _ in startAnimation() }
        .onChange(of: contentSize) { _, _ in startAnimation() }
        .onAppear { startAnimation() }
        .onDisappear { animating = false }
    }
}
