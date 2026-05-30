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
    
    @State private var isHovering = false
    
    @Environment(\.calendarLiveActivitySettings) private var prefs
    @Environment(\.openURL) private var openURL
    @Environment(\.getNow) private var getNow
    @Environment(\.notchNook) private var notchNook
    @Environment(\.enableQuickPeek) private var enableQuickPeek
    
    var quickPeeks: [NotchNookState.QuickPeek] {
        let startTime = startDate.formatted(date: .omitted, time: .shortened)
        let endTime = endDate.formatted(date: .omitted, time: .shortened)
        return [
            .init(icon: "calendar", text: event?.title ?? "", anchor: .topTrailing),
            .init(icon: "clock", text: "\(startTime) - \(endTime)", anchor: .topTrailing),
        ]
    }
        
    var body: some View {
        TimelineView(.animation(minimumInterval: 1)) { ctx in
            let now = getNow()
            let meeting = detectMeetings(in: event)
            let isEventStarted = startDate < now
            
            // Pre-call vars
            let remainingSeconds = startDate.timeIntervalSince1970 - now.timeIntervalSince1970
            let remainingNumber = formatSecs(remainingSeconds)
            let preCallText = remainingNumber
            
            // In-call vars — show time remaining until event ends
            let inCallText = prefs.showEventTimeLapsed ? formatSecs(endDate.timeIntervalSince1970 - now.timeIntervalSince1970) : nil
            
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
                        } else if meeting != nil {
                            Image(systemName: "phone.fill")
                        } else {
                            Spacer()
                        }
                    }
                    .font(.system(size: isEventStarted ? 12 : 13, weight: .medium).width(isEventStarted ? .condensed : .standard))
                    .foregroundStyle(.nonShockingWhite)
                    .padding(.horizontal, isEventStarted ? 6 : 0)
                    .padding(.vertical, isEventStarted ? 3 : 0)
                    .background(isEventStarted ? .nonShockingWhite.opacity(0.25) : .clear, in: Capsule(style: .continuous))
                    .frame(maxWidth: .infinity)
                    .blur(radius: isHovering ? 1.25 : 0)
                    .opacity(isHovering ? 0.3 : isEventStarted ? 0.5 : 1)
                    .transition(.scaleAndBlur)
                    .id(isEventStarted)
                    
                    if isHovering, let meeting {
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
                    if meeting != nil {
                        withAnimation(.smooth(duration: 0.25)) {
                            isHovering = newHovering
                        }
                    } else if enableQuickPeek {
                        notchNook.quickPeeks = newHovering ? quickPeeks : nil
                    }
                }
            }
            .animation(.spring, value: text)
            .buttonStyle(ShrinkOnClick())
            .padding(.trailing, 2)
            .frame(maxWidth: .infinity)
            .allowsHitTesting(meeting != nil || enableQuickPeek)
            .quickPeekScaling(scaling: notchNook.quickPeeks?.first?.anchor == .topTrailing, anchor: .topTrailing)
        }
    }
    
    func formatSecs(_ secs: Double) -> String {
        guard secs > 0 else { return "0s" }
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

private struct EnableQuickPeekKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var enableQuickPeek: Bool {
        get { self[EnableQuickPeekKey.self] }
        set { self[EnableQuickPeekKey.self] = newValue }
    }
}
