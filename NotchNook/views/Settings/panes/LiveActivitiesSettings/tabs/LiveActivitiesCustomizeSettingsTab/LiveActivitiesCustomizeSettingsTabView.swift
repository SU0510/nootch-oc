//
//  LiveActivitiesCustomizeSettingsTabView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI
import Defaults

struct LiveActivitiesCustomizeSettingsTabView: View {
    @Default(.liveActivitiesSettings) private var liveActivitiesSettings
    
    var body: some View {
        MultipleSettingsPicker(
            elements: LiveActivity.allCases,
            activeElements: $liveActivitiesSettings.enabledLiveActivities
        ) { selectedActivity in
            MockLiveAcitivitiesView(activity: selectedActivity)
                .padding(.horizontal, 19)
        } settings: { selectedElement in
            switch selectedElement {
            case .media: MediaLiveAcitivitySettingsView()
            case .tray: TrayLiveActivitySettingsView()
            case .calendar: CalendarLiveActivitySettingsView()
            default: BlankView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

