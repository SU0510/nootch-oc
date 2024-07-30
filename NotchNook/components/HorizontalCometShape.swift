//
//  HorizontalCometShape.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/07/24.
//

import SwiftUI

struct HorizontalCometShape: Shape {
    var leadingScale: Double = 0.33
    var trailingScale: Double = 1
    var smoothing = true
    let smoothingLength: Double = 1
    func path(in rect: CGRect) -> Path {
        let leadingHeight = rect.height * leadingScale
        let trailingHeight = rect.height * trailingScale
        let leadingCornerRadius = leadingHeight / 2
        let trailingCornerRadius = trailingHeight / 2
        
        var path = Path()
        
        // First Point
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        
        // Top left arc
        if smoothing {
            path.addQuadCurve(to: CGPoint(x: rect.minX + leadingCornerRadius + smoothingLength, y: rect.midY - leadingCornerRadius), control: CGPoint(x: rect.minX, y: rect.midY - leadingCornerRadius))
        } else {
            path.addArc(
                center: CGPoint(x: rect.minX + leadingCornerRadius, y: rect.midY),
                radius: leadingCornerRadius,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
        }
        
        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - trailingCornerRadius + (smoothing ? -smoothingLength : 0), y: rect.midY - trailingCornerRadius))
        
        // Top right arc
        if smoothing {
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.maxX, y: rect.midY - trailingCornerRadius))
        } else {
            path.addArc(
                center: CGPoint(x: rect.maxX - trailingCornerRadius, y: rect.midY),
                radius: trailingCornerRadius,
                startAngle: .degrees(270),
                endAngle: .degrees(0),
                clockwise: false
            )
        }
        
        // Bottom right arc
        if smoothing {
            path.addQuadCurve(to: CGPoint(x: rect.maxX - trailingCornerRadius - smoothingLength, y: rect.midY + trailingCornerRadius), control: CGPoint(x: rect.maxX, y: rect.midY + trailingCornerRadius))
        } else {
            path.addArc(
                center: CGPoint(x: rect.maxX - trailingCornerRadius, y: rect.midY),
                radius: trailingCornerRadius,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
        }
        
        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + leadingCornerRadius + (smoothing ? smoothingLength : 0), y: rect.midY + leadingCornerRadius))
        
        // Bottom left corner
        if smoothing {
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.minX, y: rect.midY + leadingCornerRadius))
        } else {
            path.addArc(
                center: CGPoint(x: rect.minX + leadingCornerRadius, y: rect.midY),
                radius: leadingCornerRadius,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
        }
        
        return path
    }
}
