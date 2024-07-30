//
//  BrightnessIndicatorView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/07/24.
//

import SwiftUI

struct BrightnessIndicatorView: View {
    var brightnessLevel: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Image(systemName: "sun.max")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
            HorizontalCometShape(leadingScale: 1, trailingScale: 0.33)
                .fill(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.73, green: 0.88, blue: 1), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.84, green: 0.93, blue: 1), location: 0.93),
                            Gradient.Stop(color: .white, location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0, y: 0.5),
                        endPoint: UnitPoint(x: 1, y: 0.5)
                    )
                )
                .frame(width: 100, height: 4)
                .padding(.leading, 32)
        }
    }
}
