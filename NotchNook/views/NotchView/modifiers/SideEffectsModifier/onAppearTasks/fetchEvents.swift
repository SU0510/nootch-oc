//
//  fetchEvents.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView.SideEffectsModifier {
    func fetchEvents() {
        if liveActivitiesSettings.enabledLiveActivities.contains(.calendar) {
            Task {
                _ = try? await CalendarManager.shared.fetchEventsForDaysOffset(CalendarManager.numberOfDaysToDisplay)
            }
        }
    }
}
