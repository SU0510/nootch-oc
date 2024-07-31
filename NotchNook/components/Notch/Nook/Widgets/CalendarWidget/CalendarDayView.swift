//
//  CalendarDayView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 07/06/24.
//

import SwiftUI
import SwiftDate

struct CalendarDayView: View, Equatable {
    static let width: Double = 32
    static func ==(lhs: CalendarDayView, rhs: CalendarDayView) -> Bool {
        lhs.date == rhs.date && lhs.eventsCount == rhs.eventsCount && lhs.selected == rhs.selected
    }
    var date: Date
    var eventsCount = 0
    var selected: Bool
    var body: some View {
        let isInWeekend = date.isInWeekend
        let isToday = date.isToday
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                let weekArr = Array(date.weekdayName(.standaloneShort))
                if let lA = weekArr.first {
                    Text(String(lA).uppercased())
                }
                if selected && weekArr.count > 1 {
                    Text(String(weekArr.dropFirst()).uppercased())
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.default, value: selected)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle((isInWeekend ? Color.weekendPink : Color.white).opacity(0.35))
            
            
            VStack(spacing: 1.5) {
                Text(String(format: "%02d", date.day))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isToday ? .blue : isInWeekend ? .weekendPink : .white)

                HStack(spacing: 3) {
                    if eventsCount > 0 {
                        ForEach(Array(arrayLiteral: eventsCount), id: \.self) { _ in
                            Circle().fill(.blue).frame(5)
                        }
                    }
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
}

//enum WeekDay: String {
//    case sunday, monday, tuesday, wednesday, thursday, friday, saturday
//
//    var name: String { self.rawValue.capitalized }
//    var shortName: String { self.rawValue.capitalized }
//}
