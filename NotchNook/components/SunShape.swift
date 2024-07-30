//
//  SunShape.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/07/24.
//

import SwiftUI

struct SunShape: Shape {
    var raysLength = 1.0
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let rayCount: Int = 8
        let maxRayLength: Double = (rect.width * 0.18) - 2.0
        let actualRayLength: Double = maxRayLength * raysLength
        let innerRadius: Double = rect.width * 0.18
        let rayGap: Double = rect.width * 0.16

        var path = Path()

        // Draw the center circle
        path.addArc(center: center, radius: innerRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)

        // Draw the rays
        for i in 0..<rayCount {
            let angle = Double(i) * 360 / Double(rayCount)
            let startPoint = CGPoint(
                x: center.x + (innerRadius + rayGap) * cos(Double(angle.radians)),
                y: center.y + (innerRadius + rayGap) * sin(angle.radians)
            )
            let endPoint = CGPoint(
                x: center.x + (innerRadius + rayGap + actualRayLength) * cos(Double(angle.radians)),
                y: center.y + (innerRadius + rayGap + actualRayLength) * sin(angle.radians)
            )
            path.move(to: startPoint)
            path.addLine(to: endPoint)
        }

        return path
    }
}
