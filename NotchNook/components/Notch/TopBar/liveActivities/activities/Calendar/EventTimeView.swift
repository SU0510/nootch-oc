//
//  EventTimeView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 13/06/24.
//

import SwiftUI
import EventKit
import SwiftDate

struct EventTimeView: View {
    
    var event: EKEvent?
    var startDate: Date
    var endDate: Date
    
    @State private var hovering = false
    
    @Environment(\.calendarLiveActivitySettings) private var prefs
    @Environment(\.openURL) private var openURL
    @Environment(\.getNow) private var getNow
        
    var body: some View {
        TimelineView(.animation(minimumInterval: 1)) { ctx in
            let now = getNow()
            let meeting = detectMeetings(in: event)
            let isEventStarted = startDate < now
            
            // Pre-call vars
            let remainingSeconds = startDate.timeIntervalSince1970 - now.timeIntervalSince1970
            let remainingNumber = formatSecs(remainingSeconds)
            let preCallText = remainingNumber
            
            // In-call vars
            let inCallText = prefs.showEventTimeLapsed ? formatSecs(now.timeIntervalSince1970 - startDate.timeIntervalSince1970) : nil
            
            let text = isEventStarted ? inCallText : preCallText
            
            Button {
                if let meeting, let url = URL(string: meeting.url) { openURL(url) }
            } label: {
                ZStack {
                    Group {
                        if let text {
                            Text(text)
                                .fixedSize(horizontal: true, vertical: false)
                                .contentTransition(.numericText())
                        } else {
                            Image(systemName: "phone.fill")
                        }
                    }
                    .font(.system(size: isEventStarted ? 12 : 13, weight: .medium).width(isEventStarted ? .condensed : .standard))
                    .foregroundStyle(.white)
                    .padding(.horizontal, isEventStarted ? 6 : 0)
                    .padding(.vertical, isEventStarted ? 3 : 0)
                    .background(isEventStarted ? .white.opacity(0.25) : .clear, in: Capsule(style: .continuous))
                    .frame(maxWidth: .infinity)
                    .blur(radius: hovering ? 1.25 : 0)
                    .opacity(hovering ? 0.3 : isEventStarted ? 0.5 : 1)
                    .transition(.scaleAndBlur)
                    .id(isEventStarted)
                    
                    if hovering, let meeting {
                        Image(meeting.service.logo)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 12)
                            .transition(.scaleAndBlur)
                            .opacity(0.9)
                    }
                }
                .background(.black.opacity(0.001))
                .contentShape(Rectangle())
                .onHover { newHovering in
                    if meeting == nil { return }
                    withAnimation(.smooth(duration: 0.25)) {
                        hovering = newHovering
                    }
                }
            }
            .animation(.spring, value: text)
            .buttonStyle(ShrinkOnClick())
            .padding(.trailing, 2)
            .frame(maxWidth: .infinity)
            .allowsHitTesting(meeting != nil)
        }
    }
    
    func formatSecs(_ secs: Double) -> String {
        let hours = Int(secs) / 3600
        let minutes = (Int(secs) % 3600) / 60
        let seconds = Int(secs) % 60
        
        if hours > 0 {
            //            return "\(hours)h\(minutes)m"
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}
