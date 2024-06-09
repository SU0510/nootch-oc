//
//  getRangeOfDays.swift
//  NotchNook
//
//  Created by Igor Marcossi on 09/06/24.
//

import Foundation
import SwiftDate

func getRangeOfDays(count: Int, middleDate: Date = Date()) -> [Date] {
    return (0...count / 2)
        .reversed().map { (middleDate - $0.days).startOfDay() } +
    (1...count / 2)
        .map { (middleDate + $0.days).startOfDay() }
}
