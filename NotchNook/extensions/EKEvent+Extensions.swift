//
//  EKEvent+Extensions.swift
//  NotchNook
//
//  Created by Igor Marcossi on 17/06/24.
//

import Foundation
import EventKit

extension EKEvent {
    func getNookEvent() -> NookEvent {
        .init(
            id: self.eventIdentifier,
            startDate: self.startDate,
            endDate: self.endDate,
            title: self.title,
            notes: self.notes
        )
    }
    
    var isMultiDay: Bool {
        guard let startDate = startDate, let endDate = endDate else { return false }
        return !Calendar.current.isDate(startDate, inSameDayAs: endDate)
    }
}
