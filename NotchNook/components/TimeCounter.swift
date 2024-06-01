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
    @State private var currentDate = Date().timeIntervalSince1970
    
    var body: some View {
        LabeledContent {
            Text("\(remainingTime.minutes) minutes, \(remainingTime.seconds) seconds")
        } label: {
            Label("Time Remaining", systemImage: "clock")
        }
        .onAppear(perform: setupTimer)
    }
    
    var remainingTime: (minutes: Int, seconds: Int) {
        let remainingSeconds = Int(maxTimeInHours*3600 - (currentDate - initialDate))
        return (minutes: remainingSeconds/60, seconds: remainingSeconds%60)
    }
    
    func setupTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            currentDate = Date().timeIntervalSince1970
        }
    }
}
