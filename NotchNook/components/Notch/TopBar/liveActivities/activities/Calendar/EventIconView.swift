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
    var eventTitle: String
    var startDate: Date
    var endDate: Date
    var enableQuickPeek = true
    @Environment(\.getNow) private var getNow
    @Environment(\.notchNook) private var notchNook
    
    var quickPeeks: [NotchNookState.QuickPeek] {
        let startTime = startDate.formatted(date: .omitted, time: .shortened)
        let endTime = endDate.formatted(date: .omitted, time: .shortened)
        return [
            .init(icon: "calendar", text: eventTitle),
            .init(icon: "clock", text: "\(startTime) - \(endTime)"),
        ]
    }
    var body: some View {
        let now = getNow()
        let meetingStarted = startDate < now
        Image(systemName: meetingStarted ? "calendar" : LiveActivity.calendar.icon)
            .font(.system(size: 13))
            .foregroundStyle(.blue)
            .padding(.top, 4)
            .quickPeekScaling(scaling: notchNook.quickPeeks?.first?.anchor == .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onHover { hovering in
                if enableQuickPeek {
                    notchNook.quickPeeks = hovering ? quickPeeks : nil
                }
            }
    }
}
