//
//  CalendarDayView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 07/06/24.
//

import SwiftUI
import SwiftDate

struct CalendarDayView: View, Equatable {
    
    static let width: CGFloat = 32
    
    static func ==(lhs: CalendarDayView, rhs: CalendarDayView) -> Bool {
        lhs.date == rhs.date && lhs.eventsCount == rhs.eventsCount && lhs.selected == rhs.selected
    }
    
    var date: Date
    var eventsCount = 0
    var selected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            weekDayNameView
            
            VStack(spacing: 1.5) {
                Text(String(format: "%02d", date.day))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(date.isToday ? .blue : date.isInWeekend ? .weekendPink : .nonShockingWhite)
                
                if eventsCount > 0 {
                    Circle()
                        .fill(.blue)
                        .frame(5)
                }
            }
            .compositingGroup()
            .scaleEffect(selected ? 1 : 0.65, anchor: .top)
        }
        .compositingGroup()
        .opacity(selected ? 1 : 0.5)
        .frame(width: Self.width)
        .geometryGroup()
        .contentShape(Rectangle())
        .animation(.snappy, value: selected)
    }
    
    var weekDayNameView: some View {
        HStack(spacing: 0) {
            let weekDayNameArray = Array(date.weekdayName(.standaloneShort))
            if let firstLetter = weekDayNameArray.first {
                Text(String(firstLetter).uppercased())
            }
            if selected && weekDayNameArray.count > 1 {
                // remaining letters
                Text(String(weekDayNameArray.dropFirst()).uppercased())
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.default, value: selected)
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle((date.isInWeekend ? Color.weekendPink : Color.nonShockingWhite).opacity(0.35))
    }
}
