//
//  NotchViewStatic.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/07/24.
//

import SwiftUI

extension NotchView {
    static let windowHeight: Double = 250
    static let mainVSpacing: Double = 8
    static let hoverScale: Double = 1.25
    static let animation: Animation = .bouncy(extraBounce: 0.075)
    static let intenseAnimation: Animation = .bouncy(extraBounce: 0.15)
    static let maxVPanDrag: Double = 14
    static let maxHPanDrag: Double = 24
    static let paddingWhileHovering: Double = 8
    static let panVelocityTriggerThreshold: Double = 500
    static func defaultTransition(anchor: UnitPoint, delay: Double = 0.1) -> AnyTransition { AnyTransition.asymmetric(insertion: .scaleAndBlur(anchor: anchor).animation(.smooth(duration: 0.35).delay(delay)), removal: .scaleAndBlur(anchor: anchor).animation(.smooth(duration: 0.2))) }
    static let defaultTransition = NotchView.defaultTransition(anchor: .init(x: 0.5, y: -0.25))
}
