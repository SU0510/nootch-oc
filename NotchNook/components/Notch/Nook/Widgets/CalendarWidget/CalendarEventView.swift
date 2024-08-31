//
//  CalendarEventView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 08/06/24.
//

import SwiftUI
import EventKit
import SwiftDate

struct CalendarEventView: View {
    
    static let blueCircleSize: Double = 6
    static let hSpacing: Double = 6
    
    var event: EKEvent
    var width: Double
    
    @State private var meeting: Meeting?
    @State private var hovering = false
    
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            titleView
            
            dividerView
            
            let startTime = event.startDate.formatted(date: .omitted, time: .shortened)
            let endTime = event.endDate.formatted(date: .omitted, time: .shortened)
            timeView(start: startTime, end: endTime)
        }
        .foregroundStyle(.nonShockingWhite)
        .onAppear {
            meeting = detectMeetings(in: event)
        }
        .offset(x: 3.5)
    }
    
    var titleView: some View {
        Group {
            if meeting != nil {
                Text(Image(systemName: "video.fill"))
                    .font(.system(size: 10))
                    .foregroundStyle(.blue)
                +
                Text(" \(event.title)")
            } else {
                Text(event.title)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: width / 2, alignment: .trailing)
        .opacity(hovering ? 0.35 : 1)
        .contentShape(Rectangle())
        .overlay(alignment: .trailing) {
            if let meeting, hovering {
                meetingButton(for: meeting)
            }
        }
        .onHover { x in withAnimation(.smooth(duration: 0.2, extraBounce: 0.15)) { hovering = x } }
        .font(.system(size: 13))
        .padding(.bottom, 12)
        .multilineTextAlignment(.trailing)
    }
    
    var dividerView: some View {
        VStack(spacing: -1) {
            Color.nonShockingWhite.opacity(0.1).frame(width: 1, height: 6)
            Circle().fill(.blue).frame(Self.blueCircleSize)
            Color.nonShockingWhite.opacity(0.1).frame(maxWidth: 1, maxHeight: .infinity)
        }
    }
    
    func timeView(start: String, end: String) -> some View {
        Text("\(start) - \(end)")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 12)
            .font(.system(size: 12, weight: .semibold))
            .opacity(0.5)
    }
    
    func meetingButton(for meeting: Meeting) -> some View {
        Button {
            if let url = URL(string: meeting.url)  { openURL(url) }
        } label: {
            Label {
                Text(meeting.service.rawValue)
            } icon: {
                Image(meeting.service.logo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 12)
            }
            .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
            .background(.bar.shadow(.drop(radius: 8, y: 4)), in: Capsule(style: .continuous))
            .font(.system(size: 12))
            
        }
        .buttonStyle(ShrinkOnClick(minSize: 0.9))
        .transition(.scaleAndBlur)
    }
}
