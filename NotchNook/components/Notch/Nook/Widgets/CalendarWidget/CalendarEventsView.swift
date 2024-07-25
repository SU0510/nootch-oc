//
//  CalendarEventsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 08/06/24.
//

import SwiftUI
import EventKit

struct CalendarEventsView: View {
    var events: [EKEvent]?
    
    var body: some View {
        GeometryReader { geo in
            Group {
                if let events {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(events.indices, id: \.self) { index in
                                CalendarEventView(event: events[index], width: geo.size.width)
                            }
                        }
                        .padding(EdgeInsets(top: CalendarEventsViewShadows.height, leading: 0, bottom: CalendarEventsViewShadows.height + 8, trailing: 0))
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .overlay { CalendarEventsViewShadows() }
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
        .onAppear {
            print("CalendarEventsView received events: \(events?.count ?? 0)")
        }
    }
}
