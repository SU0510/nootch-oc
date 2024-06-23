//
//  TimeCounter.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI

struct TimeCounter: View {
    var initialDate: Double
    var maxTimeInHours: Double
    
    var body: some View {
        LabeledContent {
            TimelineView(.animation(minimumInterval: 1)) { _ in
                let str = remainingTimeStr(currentDate: Date())
                Text(str)
                    .scaleEffect(1)
                    .contentTransition(.numericText())
                    .animation(.spring, value: str)
            }
        } label: {
            Label("Time Remaining", systemImage: "clock")
        }
    }
    
    func remainingTimeStr(currentDate: Date) -> String {
        let seconds = Int(maxTimeInHours*3600 - (currentDate.timeIntervalSince1970 - initialDate))
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        var result = ""
        if days > 0 { result += "\(days)d " }
        if hours > 0 { result += "\(hours)h " }
        if minutes > 0 { result += "\(minutes)m " }
        if remainingSeconds > 0 { result += "\(remainingSeconds)s" }
        return result.trimmingCharacters(in: .whitespaces)
    }
}
