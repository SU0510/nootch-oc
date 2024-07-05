//
//  getSpringAnimation.swift
//  NotchNook
//
//  Created by Igor Marcossi on 05/07/24.
//

import AppKit

func getSpringAnimation(_ keyPath: String, from: CGFloat? = nil, to: CGFloat? = nil, m: CGFloat = 1, s: CGFloat = 60, d: CGFloat = 15) -> CASpringAnimation {
    let anim = CASpringAnimation(keyPath: keyPath)
    anim.fillMode = .forwards
    anim.isRemovedOnCompletion = false
    anim.allowsOverdamping = true
    anim.mass = m
    anim.stiffness = s
    anim.damping = d
    anim.duration = anim.settlingDuration
    anim.fromValue = from
    anim.toValue = to
    return anim
}
