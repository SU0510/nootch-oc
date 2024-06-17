//
//  blurTransitions.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import Foundation
import SwiftUI

struct BlurAndFadeEffect: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .blur(radius: isActive ? 0 : 12)
    }
}

struct BlurAndSlide: ViewModifier {
    let isActive: Bool
    let top: Bool
    
    func body(content: Content) -> some View {
        content
        //                        .scaleEffect(isActive ? 1 : 0.001)
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive ? 0 : top ? -128 : 128)
            .blur(radius: isActive ? 0 : 30)
            .zIndex(isActive ? 0 : -1)
    }
}

struct BlurAndSlideH: ViewModifier {
    let isActive: Bool
    let left: Bool
    
    func body(content: Content) -> some View {
        content
        //                        .scaleEffect(isActive ? 1 : 0.001)
            .opacity(isActive ? 1 : 0)
            .offset(x: isActive ? 0 : left ? -128 : 128)
            .blur(radius: isActive ? 0 : 20)
            .zIndex(isActive ? 0 : -1)
    }
}

struct ScaleAndBlurEffect: ViewModifier {
    var blur: Double
    let isActive: Bool
    var anchor: UnitPoint = .center
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1 : 0.75, anchor: anchor)
            .opacity(isActive ? 1 : 0)
            .blur(radius: isActive ? 0 : blur)
            .zIndex(isActive ? 0 : -1)
    }
}

extension AnyTransition {
    static var leaveToTop: AnyTransition {
        .modifier(
            active: BlurAndSlide(isActive: false, top: true),
            identity: BlurAndSlide(isActive: true, top: true)
        )
    }
    static var leaveToBottom: AnyTransition {
        .modifier(
            active: BlurAndSlide(isActive: false, top: false),
            identity: BlurAndSlide(isActive: true, top: false)
        )
    }
    static var leaveToLeft: AnyTransition {
        .modifier(
            active: BlurAndSlideH(isActive: false, left: true),
            identity: BlurAndSlideH(isActive: true, left: true)
        )
    }
    static var leaveToRight: AnyTransition {
        .modifier(
            active: BlurAndSlideH(isActive: false, left: false),
            identity: BlurAndSlideH(isActive: true, left: false)
        )
    }
    static var scaleAndBlur: AnyTransition {
        .modifier(
            active: ScaleAndBlurEffect(blur: 30, isActive: false),
            identity: ScaleAndBlurEffect(blur: 30, isActive: true)
        )
    }
    static func scaleAndBlur(anchor: UnitPoint = .center, blur: Double = 30) -> AnyTransition {
        .modifier(
            active: ScaleAndBlurEffect(blur: blur, isActive: false, anchor: anchor),
            identity: ScaleAndBlurEffect(blur: blur, isActive: true, anchor: anchor)
        )
    }
    static var fadeBlur: AnyTransition {
        .modifier(
            active: BlurAndFadeEffect(isActive: false),
            identity: BlurAndFadeEffect(isActive: true)
        )
    }
}
