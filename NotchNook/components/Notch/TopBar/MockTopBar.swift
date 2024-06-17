//
//  MockTopBar.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI
import Defaults
import SwiftDate

//struct MockTopBar: View {
//    var liveActivities: Set<LiveActivity>
//    @Default(.mediaLiveActivitySettings) private var mediaLiveActivitySettings
//    var body: some View {
//        let la = liveActivities
//        let liveActionWidth = TopBarView.liveActionWidth
//        HStack(spacing: 0) {
//
//            Group {
//                if !la.isEmpty {
//                    HStack {
//                        if la.contains(.media) {
//                            AlbumCoverView(id: "sample-album", artwork: .loCafeAvatar, cornerRadius: mediaLiveActivitySettings.albumCornerRadius).padding(.all, 6)
//                        } else if la.contains(.shelf) {
//                            ShelfIconView()
//                        }
//                    }
//                    .frame(width: liveActionWidth)
//                }
//            }
//            .transition(.scaleAndBlur(anchor: .topTrailing))
//
//            TopBarSpacerView(height: TopBarView.height)
//
//            Group {
//                if !la.isEmpty {
//                    HStack {
//                        if la.contains(.shelf) {
//                            ShelfFilesCountView()
//                        } else if la.contains(.media) {
//                            AudioWavesView(
//                                altImg: .loCafeAvatar,
//                                altIsPlaying: true,
//                                prefs: mediaLiveActivitySettings
//                            )
//                        }
//                    }
//                    .frame(width: liveActionWidth)
//                }
//            }
//            .transition(.scaleAndBlur(anchor: .topTrailing))
//
//        }
//        .frame(height: TopBarView.height)
//    }
//}









struct MockTopBar: View {
    var activity: LiveActivity
    @Environment(\.notchHeight) private var notchHeight
    @Default(.mediaLiveActivitySettings) private var mediaLiveActivitySettings
    @Default(.gestureControlSettings) private var gestureControlSettings
    @Default(.liveActivitiesSettings) private var liveActivitiesSettings
    @Default(.calendarLiveActivitySettings) private var calendarLiveActivitySettings
    @Default(.nookSettings) private var nookSettings
    @Default(.shelfSettings) private var shelfSettings
    @SilentState private var fakeNow = Date()
    
    func staticNow() -> Date {
//        fakeNow - calendarLiveActivitySettings.minutesBeforeEvent.minutes
        fakeNow + 59.minutes
    }
    
    var body: some View {
        let height = notchHeight > ((TopBarView.height / 3) * 2) ? notchHeight : TopBarView.height
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
                    case .calendar: EventIconView(eventTitle: mockedEvent.title, startDate: mockedEvent.startDate, laPrefs: liveActivitiesSettings).environment(\.getNow, staticNow)
                    case .media: AlbumCoverView(id: "sample-album", artwork: .loCafeAvatar, cornerRadius: mediaLiveActivitySettings.albumCornerRadius).padding(.all, 6)
                    case .shelf: ShelfIconView()
                }
            }
            .frame(width: TopBarView.liveActionWidth)
            .transition(NotchView.defaultTransition(anchor: .trailing, delay: 0.075))
            .allowsHitTesting(liveActivitiesSettings.interactive)
            
            TopBarSpacerView(height: height)
            
            Group {
                switch activity {
                    case .calendar: EventTimeView(notes: mockedEvent.notes, startDate: mockedEvent.startDate, endDate: mockedEvent.endDate, prefs: calendarLiveActivitySettings).environment(\.getNow, staticNow)
                    case .media: AudioWavesView(prefs: mediaLiveActivitySettings)
                    case .shelf: ShelfFilesCountView()
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
