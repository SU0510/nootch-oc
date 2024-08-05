//
//  ScrollableDaysMonthOverlayView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 31/07/24.
//

import SwiftUI

struct ScrollableDaysMonthOverlayView: View, Equatable {
    static func == (lhs: ScrollableDaysMonthOverlayView, rhs: ScrollableDaysMonthOverlayView) -> Bool {
        lhs.monthName == rhs.monthName
    }
    
    var monthName: String
    var action: () -> ()
    var body: some View {
        Button(action: action) {
            VStack {
                Text(monthName)
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 3)
                    .padding(.leading, 10)
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
            .foregroundStyle(.white)
        }
        .buttonStyle(ShrinkOnClick(minSize: 0.9))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
