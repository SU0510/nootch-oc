//
//  CalendarEventView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 08/06/24.
//

import SwiftUI
import EventKit
import SwiftDate

struct CalendarEventView: View {
    static let blurCircleSize: Double = 5
    static let hSpacing: Double = 6
    var event: EKEvent
    var width: Double
    var body: some View {
        HStack(alignment: .top, spacing: 6) {

            Text(event.title)
                .fixedSize(horizontal: false, vertical: true)
                .frame(
                    width: ((width - (Self.hSpacing * 2) - Self.blurCircleSize) / 2) + (ScrollableDaysView.leadingPadding / 2),
                    alignment: .trailing
                )
                .font(.system(size: 13))
                .padding(.bottom, 12)
                .multilineTextAlignment(.trailing)
            
            VStack(spacing: -1) {
                Color.white.opacity(0.1).frame(width: 1, height: 3)
                Circle().fill(.blue).frame(Self.blurCircleSize)
                Color.white.opacity(0.1).frame(maxWidth: 1, maxHeight: .infinity)
            }
            
            let startTime = event.startDate.formatted(date: .omitted, time: .shortened)
            let endTime = event.endDate.formatted(date: .omitted, time: .shortened)
            Text("\(startTime) - \(endTime)")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)
                .font(.system(size: 12, weight: .semibold))
                .opacity(0.5)

        }
        .foregroundStyle(.white)
    }
}
