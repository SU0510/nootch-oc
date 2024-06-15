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
    static let blurCircleSize: Double = 6
    static let hSpacing: Double = 6
    var event: EKEvent
    var width: Double
    @State private var meeting: Meeting?
    @State private var hovering = false
    @Environment(\.openURL) private var openURL
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            
            Group {
                if meeting != nil {
                    Text(Image(systemName: "video.fill")).font(.system(size: 10)).foregroundStyle(.blue) + Text(" \(event.title)")
                } else {
                    Text(event.title)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(
                width: ((width - (Self.hSpacing * 2) - Self.blurCircleSize) / 2) + (ScrollableDaysView.leadingPadding / 2),
                alignment: .trailing
            )
            .opacity(hovering ? 0.35 : 1)
            .contentShape(Rectangle())
            .overlay(alignment: .trailing) {
                if let meeting, hovering {
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
            .onHover { x in withAnimation(.smooth(duration: 0.2, extraBounce: 0.15)) { hovering = x } }
            .font(.system(size: 13))
            .padding(.bottom, 12)
            .multilineTextAlignment(.trailing)
            
            VStack(spacing: -1) {
                Color.white.opacity(0.1).frame(width: 1, height: 6)
                Circle().fill(.blue).frame(Self.blurCircleSize)
                Color.white.opacity(0.1).frame(maxWidth: 1, maxHeight: .infinity)
            }
            
            let startTime = event.startDate.formatted(date: .omitted, time: .shortened)
            let endTime = event.endDate.formatted(date: .omitted, time: .shortened)
            Text("\(startTime) - \(endTime)")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)
                .font(.system(size: 12, weight: .semibold))
                .opacity(0.5)
            
        }
        .foregroundStyle(.white)
        .onAppear {
            if let notes = event.notes { meeting = detectMeetings(notes) }
        }
    }
}
