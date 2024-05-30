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
    @State private var selectedActivity: LiveActivity?
    
    func selectActivity(_ activity: LiveActivity) {
        selectedActivity = activity
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            MockLiveAcitivitiesView(activities: selectedActivity == nil ? [] : [selectedActivity!])
                .padding(.horizontal, 19)
            
            MultipleSettingsPicker(
                elements: LiveActivity.allCases,
                activeElements: $liveActivitiesSettings.enabledLiveActivities,
                selectedElement: $selectedActivity
            ) {
                switch selectedActivity {
                case .media: MediaLiveAcitivitySettingsView()
                case .shelf: ShelfLiveActivitySettingsView()
                case .none: BlankView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}

