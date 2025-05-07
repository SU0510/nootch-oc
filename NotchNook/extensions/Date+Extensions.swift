//
//  Date+Extensions.swift
//  NotchNook
//
//  Created by Lori Montenegro on 24/07/24.
//

import Foundation

extension Date {
    func startOfDay(calendar: Calendar = .autoupdatingCurrent) -> Date {
        calendar.startOfDay(for: self)
    }
    
    func endOfDay(calendar: Calendar = .autoupdatingCurrent) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfDay(calendar: calendar))!
    }
    
    func isSameDay(as date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: date)
    }
}
