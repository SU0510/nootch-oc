//
//  CalendarEventsViewShadows.swift
//  NotchNook
//
//  Created by Lori Montenegro on 24/07/24.
//

import SwiftUI
import SmoothGradient

struct CalendarEventsViewShadows: View, Equatable {
    static let height: Double = 16
    var body: some View {
        VStack(spacing:0) {
            SmoothLinearGradient(
                from: .black,
                to: .black.opacity(0),
                startPoint: .top,
                endPoint: .bottom,
                curve: .easeInOut
            )
            .frame(height: Self.height)
            Spacer()
            SmoothLinearGradient(
                from: .black,
                to: .black.opacity(0),
                startPoint: .bottom,
                endPoint: .top,
                curve: .easeInOut
            )
            .frame(height: Self.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}
