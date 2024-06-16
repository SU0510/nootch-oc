//
//  EventIconView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 13/06/24.
//

import SwiftUI
import EventKit
import SwiftDate

struct EventIconView: View {
    var event: EKEvent
    var laPrefs: LiveActivitiesSettings
    var body: some View {
        let now = Date()
        let meetingStarted = event.startDate < now
        Image(systemName: meetingStarted ? "calendar" : LiveActivity.calendar.icon)
            .font(.system(size: 13))
            .foregroundStyle(.blue)
            .scaleEffect(NotchNook.shared.quickPeaks == nil ? 1 : 1.2, anchor: .topLeading)
            .frame(maxWidth: .infinity)
            .onHover { hovering in
                if laPrefs.enableQuickPeak {
                    NotchNook.shared.quickPeaks = hovering ? [.init(icon: "calendar.circle.fill", text: event.title)] : nil
                }
            }
    }
}

