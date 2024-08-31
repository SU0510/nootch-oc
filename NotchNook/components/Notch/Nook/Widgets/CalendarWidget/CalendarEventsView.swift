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
    @State private var eventHeights: [String: CGFloat] = [:]
    
    let id = UUID()
    
    var isAccessNotGranted: Bool {
        let status = CalendarManager.shared.authorizationStatus
        return status != .fullAccess
    }
    
    var body: some View {
        GeometryReader { geo in
            Group {
                if let events = events, !events.isEmpty {
                    eventsScrollView(geo: geo)
                    .fadeOnEdges(axis: .vertical, fadeLength: Self.fadeHeight, curve: .easeInOut)
                } else {
                    emptyView
                }
            }
            .transition(.scaleAndBlur)
        }
        .id(id)
    }
    
    func eventsScrollView(geo: GeometryProxy) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            eventsStackView(geo: geo)
        }
        .coordinateSpace(name: "ScrollView")
        .onAppear {
            doAfter { scrollToInitialPosition() }
        }
        .onChange(of: selectedDate) {
            doAfter { scrollToInitialPosition() }
        }
    }
    
    func eventsStackView(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            ForEach(events ?? [], id: \.self) { event in
                CalendarEventView(event: event, width: geo.size.width)
                    .id("\(event.eventIdentifier)_\(event.startDate.timeIntervalSince1970)")
                    .background(
                        GeometryReader { itemGeo in
                            Color.clear.onAppear {
                                let frame = itemGeo.frame(in: .named("ScrollView"))
                                eventHeights["\(event.eventIdentifier)_\(event.startDate.timeIntervalSince1970)"] = frame.height
                            }
                        }
                    )
            }
        }
        .padding(EdgeInsets(top: Self.fadeHeight, leading: 8, bottom: Self.fadeHeight + 8, trailing: 8))
        .offset(y: -scrollOffset)
    }
    
    var emptyView: some View {
        VStack {
            Image(systemName: "calendar.badge.checkmark")
            Text(isAccessNotGranted ? "This widget requires calendar permissions in order to show events, please enable access in settings." : "Nothing for today")
                .foregroundStyle(.nonShockingWhite)
                .multilineTextAlignment(.center)
        }
        .opacity(0.5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func scrollToInitialPosition() {
//        guard let events = events, !events.isEmpty else { return }
//        
//        var targetOffset: CGFloat = 0
//        
//        if Calendar.current.isDateInToday(selectedDate) {
//            guard let nextEventIndex = events.firstIndex(where: { $0.startDate >= Date() }) else { return }
//            
//            for i in 0..<nextEventIndex {
//                let eventId = "\(events[i].eventIdentifier)_\(events[i].startDate.timeIntervalSince1970)"
//                targetOffset += eventHeights[eventId] ?? 0
//            }
//        }
//        
//        withAnimation(.easeInOut(duration: 0.3)) {
//            scrollOffset = targetOffset
//        }
    }
}
