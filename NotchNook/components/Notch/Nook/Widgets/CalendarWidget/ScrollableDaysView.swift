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

struct ScrollableDaysView: View, Equatable {
    static let leadingPadding: Double = 40
    static func == (lhs: ScrollableDaysView, rhs: ScrollableDaysView) -> Bool {
        lhs.showingDates == rhs.showingDates && lhs.selectedDateIndex == rhs.selectedDateIndex && lhs.offset == rhs.offset && 
        lhs.events.values.reduce(0, { $0 + $1.count }) == rhs.events.values.reduce(0, { $0 + $1.count })
    }
    
    var showingDates: [Date]
    @Binding var selectedDateIndex: Int
    @Binding var offset: Double
    var events: [Date:[EKEvent]]
    //    @State private var scrollPos: Double = 0
    
    var selectedDate: Date {
        if selectedDateIndex < 0 { return showingDates[0] }
        if selectedDateIndex >= showingDates.count { return showingDates[showingDates.count - 1] }
        return showingDates[selectedDateIndex]
    }
    
    var scrollPos: Double {
        let initialIndex = showingDates.count / 2
        let movedDates = initialIndex - selectedDateIndex
        let newScrollPos = Double(movedDates) * CalendarDayView.width
        return newScrollPos
    }
    
    var body: some View {
        let actualScroll = scrollPos + offset
        GeometryReader { geo in
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 0) {
                    ForEach(Array(showingDates.enumerated()), id: \.element.timeIntervalSince1970) { i, date in
                        CalendarDayView(date: date, eventsCount: events[date]?.count ?? 0, selected: selectedDateIndex == i)
                            .onTapGesture { setDateToIndex(i) }
                    }
                }
                .geometryGroup()
                .offset(x: actualScroll)
                .padding(.leading, Self.leadingPadding)
                .frame(width: geo.size.width, alignment: .top)
                .clipped()
                .overlay {
                    ScrollableDaysOverlayView(monthName: selectedDate.monthName(.standaloneShort)) {
                        withAnimation(.spring) {
                            selectedDateIndex = showingDates.count / 2
                        }
                    }
                }
            }
            .scrollDisabled(true)
        }
        .frame(height: 43)
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

struct ScrollableDaysOverlayView: View, Equatable {
    static func == (lhs: ScrollableDaysOverlayView, rhs: ScrollableDaysOverlayView) -> Bool {
        lhs.monthName == rhs.monthName
    }
    
    var monthName: String
    var action: () -> ()
    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing:0) {
                SmoothLinearGradient(
                    from: .black,
                    to: .black.opacity(0),
                    startPoint: .leading,
                    endPoint: .trailing,
                    curve: .easeIn
                )
                .frame(width: 105)
                Spacer()
                SmoothLinearGradient(
                    from: .black,
                    to: .black.opacity(0),
                    startPoint: .trailing,
                    endPoint: .leading,
                    curve: .easeInOut
                )
                .frame(width: 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(1)
            .allowsHitTesting(false)
            
            Button(action: action) {
                VStack {
                    Text(monthName)
                        .font(.system(size: 24, weight: .bold))
                        .padding(.top, 3)
                        .padding(.leading, 10)
                        .transition(.scale.combined(with: .opacity))
                        .id(monthName)
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
                .foregroundStyle(.white)
            }
            .buttonStyle(ShrinkOnClick(minSize: 0.9))
            .zIndex(2)
        }
        .animation(.snappy, value: monthName)
    }
}
