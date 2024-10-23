//
//  getSpringAnimation.swift
//  NotchNook
//
//  Created by Igor Marcossi on 05/07/24.
//

import AppKit

func getSpringAnimation(_ keyPath: String, from: CGFloat? = nil, to: CGFloat? = nil, mass: CGFloat = 1, stiffness: CGFloat = 60, damping: CGFloat = 15) -> CASpringAnimation {
    let anim = CASpringAnimation(keyPath: keyPath)
    anim.fillMode = .forwards
    anim.isRemovedOnCompletion = false
    anim.allowsOverdamping = true
    anim.mass = mass
    anim.stiffness = stiffness
    anim.damping = damping
    anim.duration = anim.settlingDuration
    anim.fromValue = from
    anim.toValue = to
    return anim
}
