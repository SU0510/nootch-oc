//
//  EventTimeRemainingView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 13/06/24.
//

import SwiftUI
import EventKit

struct EventTimeRemainingView: View {
    var event: EKEvent
    @State private var remainingSeconds: Int = 0

    var body: some View {
        Text("\(remainingSeconds) seconds remaining")
            .font(.system(size: 13))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .onAppear {
                startTimer()
            }
    }

    private func startTimer() {
        let endDate = event.endDate ?? Date()
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let now = Date()
            if now >= endDate {
                self.remainingSeconds = 0
                timer.invalidate()
            } else {
                self.remainingSeconds = Int(endDate.timeIntervalSince(now))
            }
        }
    }
}
