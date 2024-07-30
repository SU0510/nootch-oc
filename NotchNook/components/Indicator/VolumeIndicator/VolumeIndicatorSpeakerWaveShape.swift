//
//  VolumeIndicatorSpeakerWaveShape.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/07/24.
//

import SwiftUI

struct VolumeIndicatorSpeakerWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        let controlPointLength = rect.height * 0.28571429
        
        var path = Path()
        
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
        
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.midY + controlPointLength))
        
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
        
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY), control: CGPoint(x: rect.maxX, y: rect.midY - controlPointLength))
        
        return path
    }
}
