//
//  getRangeOfDays.swift
//  NotchNook
//
//  Created by Igor Marcossi on 09/06/24.
//

import Foundation
import SwiftDate

func getRangeOfDays(count: Int, middleDate: Date = Date()) -> [Date] {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: middleDate)
    let currentTimeComponents = calendar.dateComponents([.hour, .minute, .second], from: middleDate)
    
    var dates: [Date] = []
    for i in (0...count / 2).reversed() {
        if let date = calendar.date(byAdding: .day, value: -i, to: startOfDay) {
            dates.append(calendar.date(bySettingHour: currentTimeComponents.hour!, minute: currentTimeComponents.minute!, second: currentTimeComponents.second!, of: date)!)
        }
    }
    for i in 1...count / 2 {
        if let date = calendar.date(byAdding: .day, value: i, to: startOfDay) {
            dates.append(calendar.date(bySettingHour: currentTimeComponents.hour!, minute: currentTimeComponents.minute!, second: currentTimeComponents.second!, of: date)!)
        }
    }
    
    return dates
}
