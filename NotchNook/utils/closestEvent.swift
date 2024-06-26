//
//  closestEvent.swift
//  NotchNook
//
//  Created by Igor Marcossi on 15/06/24.
//

import Foundation
import EventKit
import SwiftDate

func closestEvent(in events: [EKEvent]) -> EKEvent? {
    if events.isEmpty { return nil }
    let now = Date()
    return events.min(by: { abs($0.startDate.timeIntervalSince(now)) < abs($1.startDate.timeIntervalSince(now)) })
}
