//
//  MockTopBar.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI
import Defaults
import SwiftDate

struct MockTopBar: View {
    var activity: LiveActivity
    @Environment(\.notchSize) private var notchSize
    @Environment(\.mediaLiveActivitySettings) private var mediaLiveActivitySettings
    @Environment(\.gestureControlSettings) private var gestureControlSettings
    @Environment(\.liveActivitiesSettings) private var liveActivitiesSettings
    @Environment(\.calendarLiveActivitySettings) private var calendarLiveActivitySettings
    @Environment(\.nookSettings) private var nookSettings
    @Environment(\.traySettings) private var traySettings
    @SilentState private var fakeNow = Date()
    
    func staticNow() -> Date {
        fakeNow - calendarLiveActivitySettings.minutesBeforeEvent.minutes
    }
    
    var body: some View {
        let height = notchSize.height > ((TopBarView.minHeight / 3) * 2) ? notchSize.height : TopBarView.minHeight
        let mockedEvent = NookEvent(
            id: "mock-event",
            startDate: fakeNow,
            endDate: fakeNow + 1.hours,
            title: "",
            notes: nil
        )
        
        HStack(spacing: 0) {
            
            Group {
                switch activity {
                    case .calendar: EventIconView(eventTitle: mockedEvent.title, startDate: mockedEvent.startDate, endDate: mockedEvent.endDate, enableQuickPeek: liveActivitiesSettings.enableQuickPeek).environment(\.getNow, staticNow)
                    case .media: AlbumCoverView(id: "sample-album", artwork: .loCafeAvatar, cornerRadius: mediaLiveActivitySettings.albumCornerRadius).padding(.all, 6)
                    case .tray: TrayIconView()
                    case .updateAvailable: UpdateAppIconView(enableQuickPeek: liveActivitiesSettings.enableQuickPeek)
                }
            }
            .frame(width: TopBarView.liveActionWidth)
            .transition(NotchView.defaultTransition(anchor: .trailing, delay: 0.075))
            .allowsHitTesting(liveActivitiesSettings.interactive)
            
            TopBarSpacerView(height: height)
            
            Group {
                switch activity {
                    case .calendar: EventTimeView(startDate: mockedEvent.startDate, endDate: mockedEvent.endDate).environment(\.getNow, staticNow)
                    case .media: AudioWavesView()
                    case .tray: TrayFilesCountView()
                    case .updateAvailable: UpdateButtonIconView()
                }
            }
            .frame(width: TopBarView.liveActionWidth)
            .transition(NotchView.defaultTransition(anchor: .leading, delay: 0.075))
            .allowsHitTesting(liveActivitiesSettings.interactive)
            
        }
        .animation(.smooth(extraBounce: 0.25), value: activity)
        .frame(height: height)
        .fixedSize(horizontal: false, vertical: true)
        .zIndex(1)
        .allowsHitTesting(false)
    }
}
