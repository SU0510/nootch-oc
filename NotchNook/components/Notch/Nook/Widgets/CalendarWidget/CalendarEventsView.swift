//
//  CalendarEventsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 08/06/24.
//

import SwiftUI
import EventKit
import SwiftDate

struct CalendarEventsView: View {
    static let fadeHeight: Double = 16
    var events: [EKEvent]?
    var selectedDate: Date
    
    @State private var scrollOffset: CGFloat = 0
    
    let id = UUID()
    
    var isAccessNotGranted: Bool {
        let status = CalendarManager.shared.authorizationStatus
        return status != .fullAccess
    }
    
    var body: some View {
        GeometryReader { geo in
            Group {
                if let events = events, !events.isEmpty {
                    // MARK: Scroll view
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(events.enumerated()), id: \.element) { (index, event) in
                                CalendarEventView(event: event, width: geo.size.width, selectedDate: selectedDate, isLastEvent: index == events.count - 1)
                            }
                        }
                        .padding(EdgeInsets(top: Self.fadeHeight, leading: 8, bottom: Self.fadeHeight + 8, trailing: 8))
                        .offset(y: -scrollOffset)
                    }
                    .coordinateSpace(name: "ScrollView")
                    .fadeOnEdges(axis: .vertical, fadeLength: Self.fadeHeight, curve: .easeInOut)
                    .scrollBounceBehavior(.basedOnSize)
                } else {
                    // MARK: Empty view
                    VStack {
                        Image(systemName: "calendar.badge.checkmark")
                        Text(isAccessNotGranted ? "This widget requires calendar permissions in order to show events, please enable access in settings." : "Nothing for today")
                            .foregroundStyle(.nonShockingWhite)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(0.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .transition(.scaleAndBlur)
        }
        .id(id)
    }
    
}
