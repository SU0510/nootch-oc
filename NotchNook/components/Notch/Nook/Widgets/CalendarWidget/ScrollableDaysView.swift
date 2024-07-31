//
//  ScrollableDaysView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 07/06/24.
//

import SwiftUI
import SmoothGradient
import EventKit
import SwiftDate

struct ScrollableDaysView: View {
    static let leadingPadding: Double = 40
//    static func == (lhs: ScrollableDaysView, rhs: ScrollableDaysView) -> Bool {
//        lhs.showingDates == rhs.showingDates && lhs.selectedDateIndex == rhs.selectedDateIndex && lhs.offset == rhs.offset &&
//        lhs.events.values.reduce(0, { $0 + $1.count }) == rhs.events.values.reduce(0, { $0 + $1.count })
//    }
    
    var showingDates: [Date]
    @Binding var selectedDateIndex: Int
    @Binding var offset: Double
    var events: [Date:[EKEvent]]
    //    @State private var scrollPos: Double = 0
    
    var scrollPos: Double {
        let initialIndex = showingDates.count / 2
        let movedDates = initialIndex - selectedDateIndex
        let newScrollPos = Double(movedDates) * CalendarDayView.width
        return newScrollPos
    }
    
    var body: some View {
        let actualScroll = scrollPos + offset
        let calendar = Calendar.current
        
        GeometryReader { geo in
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 0) {
                    ForEach(Array(showingDates.enumerated()), id: \.element.timeIntervalSince1970) { i, date in
                        let actualDate = calendar.startOfDay(for: date)
                        CalendarDayView(date: actualDate, eventsCount: events[actualDate]?.count ?? 0, selected: selectedDateIndex == i)
                            .onTapGesture { setDateToIndex(i) }
                    }
                }
                .geometryGroup()
                .offset(x: actualScroll)
                .padding(.leading, Self.leadingPadding)
                .frame(width: geo.size.width, alignment: .top)
                .clipped()
                .fadeOnEdges(axis: .horizontal, topLeadingFadeLength: 105, bottomTrailingFadeLength: 30, curveStart: .easeIn, curveEnd: .easeInOut)
            }
            .scrollDisabled(true)
        }
        .frame(height: 44)
        .animation(.spring, value: offset == 0)
        .onChange(of: offset) { oldOffset, newOffset in
            if oldOffset == newOffset { return }
            if abs(newOffset) > (CalendarDayView.width / 2) {
                withAnimation(.snappy) {
                    vibrate()
                    selectedDateIndex += newOffset < 0 ? 1 : -1
                    offset = (CalendarDayView.width / 2) * (offset > 0 ? -1 : 1)
                }
            }
        }
    }
    
    // MARK: - Functions
    
    func setDateToIndex(_ index: Int) {
        withAnimation(.snappy) {
            selectedDateIndex = index
            offset = 0
        }
    }
    
}
