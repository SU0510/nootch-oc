//
//  getRangeOfDays.swift
//  NotchNook
//
//  Created by Igor Marcossi on 09/06/24.
//

import Foundation
import SwiftDate

func getRangeOfDays(beforeCount: Int, afterCount: Int, middleDate: Date = Date()) -> [Date] {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: middleDate)
    let currentTimeComponents = calendar.dateComponents([.hour, .minute, .second], from: middleDate)
    
    var dates: [Date] = []
    
    // Add dates before middleDate
    if beforeCount > 0 {
        for i in (1...beforeCount).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: startOfDay),
               let adjustedDate = calendar.date(bySettingHour: currentTimeComponents.hour ?? 0, minute: currentTimeComponents.minute ?? 0, second: currentTimeComponents.second ?? 0, of: date) {
                dates.append(adjustedDate)
            }
        }
    }
    
    // Add middleDate
    dates.append(middleDate)
    
    // Add dates after middleDate
    if afterCount > 0 {
        for i in 1...afterCount {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfDay),
               let adjustedDate = calendar.date(bySettingHour: currentTimeComponents.hour ?? 0, minute: currentTimeComponents.minute ?? 0, second: currentTimeComponents.second ?? 0, of: date) {
                dates.append(adjustedDate)
            }
        }
    }
    
    return dates
}
