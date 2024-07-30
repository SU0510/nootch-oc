//
//  VolumeIndicatorBarCapsuleView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/07/24.
//

import SwiftUI
import DynamicColor

struct VolumeIndicatorBarCapsuleView: View {
    var color: Color
    var active: Bool
    var body: some View {
        let shadowColor = Color(nsColor: NSColor(color).lighter())
        Capsule()
            .fill(
                color
                    .shadow(.drop(color: shadowColor.opacity(!active ? 0 : 1), radius: 4, x: 0, y: 0))
                    .shadow(.drop(color: shadowColor.opacity(!active ? 0 : 1), radius: 16, x: 0, y: 0))
                    .shadow(.drop(color: shadowColor.opacity(!active ? 0 : 1), radius: 24, x: 0, y: 0))
            )
            .overlay {
                ZStack {
                    let strokeWidth = 0.5
                    
                    Group {
                        // Bottom dark border
                        Capsule()
                            .stroke(
                                LinearGradient(colors: [Color(hexString: "B4B4B4"), Color(hexString: "B4B4B4").opacity(0)], startPoint: .bottom, endPoint: .top)
                                    .opacity(!active ? 0 : 1),
                                lineWidth: strokeWidth
                            )
                            .blendMode(.plusDarker)
                        
                        // Top light border
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hexString: "3D3D3D"), Color(hexString: "3D3D3D").opacity(0)], startPoint: .top, endPoint: .bottom)
                                    .opacity(!active ? 0 : 1),
                                lineWidth: strokeWidth
                            )
                            .blendMode(.plusLighter)
                    }
                    .padding(strokeWidth)
                }
            }
            .overlay {
                Capsule()
                    .fill(
                        LinearGradient(colors: [Color(hexString: "3A3A3A"), Color(hexString: "3A3A3A").opacity(0)], startPoint: .top, endPoint: .bottom))
                    .blendMode(.plusLighter).opacity(!active ? 0 : 1)
            }
    }
}
