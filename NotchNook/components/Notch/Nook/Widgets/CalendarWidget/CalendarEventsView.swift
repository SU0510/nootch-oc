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
    var selectedDate: Date
    
    @State private var scrolledToInitialPosition = false
    
    var body: some View {
        GeometryReader { geo in
            Group {
                if let events = events, !events.isEmpty {
                    eventsScrollView(geo: geo)
                } else {
                    emptyView
                }
            }
            .transition(.scaleAndBlur)
        }
    }
    
    func eventsScrollView(geo: GeometryProxy) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(events ?? [], id: \.eventIdentifier) { event in
                        CalendarEventView(event: event, width: geo.size.width)
                            .id(event.eventIdentifier)
                    }
                }
                .padding(EdgeInsets(top: CalendarEventsViewShadows.height, leading: 0, bottom: CalendarEventsViewShadows.height + 8, trailing: 0))
            }
            .onAppear {
                scrollToInitialPosition(proxy: proxy)
            }
            .onChange(of: selectedDate) { _ in
                scrollToInitialPosition(proxy: proxy)
            }
            .overlay { CalendarEventsViewShadows() }
        }
    }
    
    var emptyView: some View {
        VStack {
            Image(systemName: "calendar.badge.checkmark")
            Text("Nothing for today")
                .foregroundStyle(.white)
        }
        .opacity(0.5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Methods
    
    private func indexOfFirstUpcomingEvent() -> Int? {
        guard Calendar.current.isDateInToday(selectedDate) else { return nil }
        let now = Date()
        return events?.firstIndex(where: { $0.startDate >= now })
    }
    
    private func scrollToInitialPosition(proxy: ScrollViewProxy) {
        guard !scrolledToInitialPosition else { return }
        
        if Calendar.current.isDateInToday(selectedDate) {
            if let index = indexOfFirstUpcomingEvent() {
                withAnimation {
                    proxy.scrollTo(events?[index].eventIdentifier, anchor: .top)
                }
            }
        } else {
            withAnimation {
                proxy.scrollTo(events?.first?.eventIdentifier, anchor: .top)
            }
        }
        
        scrolledToInitialPosition = true
    }
}
