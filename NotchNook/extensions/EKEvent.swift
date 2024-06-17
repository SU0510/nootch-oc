//
//  EKEvent.swift
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
}
