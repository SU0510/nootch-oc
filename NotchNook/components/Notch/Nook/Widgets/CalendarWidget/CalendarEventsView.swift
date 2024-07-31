//
//  CalendarEventsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 08/06/24.
//

import SwiftUI
import EventKit
import SmoothGradient

struct CalendarEventsView: View {
    static let fadeHeight: Double = 16
    var events: [EKEvent]?
    var body: some View {
        GeometryReader { geo in
            Group {
                if let events {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(events, id: \.eventIdentifier) { event in
                                CalendarEventView(event: event, width: geo.size.width)
                            }
                        }
                        .padding(EdgeInsets(top: Self.fadeHeight, leading: 0, bottom: Self.fadeHeight + 8, trailing: 0))
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .fadeOnEdges(axis: .vertical, fadeLength: Self.fadeHeight, curve: .easeInOut)
                } else {
                    VStack {
                        Image(systemName: "calendar.badge.checkmark")
                        Text("Nothing for today")
                            .foregroundStyle(.white)
                    }
                    .opacity(0.5)
                    .frame(geo.size)
                }
            }
            .transition(.scaleAndBlur)
        }
    }
}
