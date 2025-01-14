//
//  RoundedTriangle.swift
//  NotchNook
//
//  Created by Lori Montenegro on 13/01/25.
//

import SwiftUI

struct RoundedTriangle: Shape {
    var cornerRadius: CGFloat = 1.1
    
    func path(in rect: CGRect) -> Path {
        let radius = min(cornerRadius, min(rect.width, rect.height) / 2)
        let height = min(rect.width, rect.height)
        let width = height * sqrt(3) / 2
        
        return Path { path in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let p1 = CGPoint(x: center.x + width/2, y: center.y)
            let p2 = CGPoint(x: center.x - width/2, y: center.y - height/2)
            let p3 = CGPoint(x: center.x - width/2, y: center.y + height/2)
            
            path.move(to: midPoint(p1, p2))
            
            path.addArc(tangent1End: p1, tangent2End: p3, radius: radius)
            path.addArc(tangent1End: p3, tangent2End: p2, radius: radius)
            path.addArc(tangent1End: p2, tangent2End: p1, radius: radius)
            
            path.closeSubpath()
        }
    }
    
    private func midPoint(_ p1: CGPoint, _ p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }
}
