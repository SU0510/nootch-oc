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
    
    var displayedDates: [Date]
    
    @Binding var selectedDateIndex: Int
    @Binding var offset: Double
    
    var events: [Date:[EKEvent]]
            
    var scrollPos: Double {
        let totalWidth = Double(displayedDates.count) * CalendarDayView.width
        let centerPosition = totalWidth / 2
        let selectedPosition = Double(selectedDateIndex) * CalendarDayView.width
        return centerPosition - selectedPosition - CalendarDayView.width / 2
    }
    
    var body: some View {
        let actualScroll = scrollPos + offset
        let calendar = Calendar.current
        
        GeometryReader { geo in
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 0) {
                    ForEach(Array(displayedDates.enumerated()), id: \.element.timeIntervalSince1970) { i, date in
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
                    let direction = newOffset < 0 ? 1 : -1
                    let newIndex = selectedDateIndex + direction
                    
                    // Only update if within bounds
                    if newIndex >= 0 && newIndex < displayedDates.count {
                        selectedDateIndex = newIndex
                        offset = 0
                    } else {
                        // If we're at the edge, bounce back
                        offset = 0
                    }
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
