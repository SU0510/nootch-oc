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
    @State private var selectedActivity: NotchNook.LiveActivity?
    
    func selectActivity(_ activity: NotchNook.LiveActivity) {
        selectedActivity = activity
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            
            VStack(alignment: .center, spacing: 16) {
                MockLiveAcitivitiesView(activities: selectedActivity == nil ? [] : [selectedActivity!])
                
                ScrollView(.horizontal) {
                    HStack(alignment: .center, spacing: 4) {
                        let las = NotchNook.LiveActivity.allCases
                        ForEach(Array(las.enumerated()), id: \.element.rawValue) { i, activity in
                            SettingsActivityItemView(
                                activity: activity,
                                selected: selectedActivity == activity,
                                select: selectActivity,
                                isOn: Binding.setMembership(of: activity, in: $liveActivitiesSettings.enabledLiveActivities)
                            )
                            
                            if i < (las.count - 1) {
                                VDivider(color: .primary.opacity(0.1))
                            }
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(6)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .background(.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .padding(.horizontal, 19)
            
            //            VStack {
            switch selectedActivity {
            case .media: MediaLiveAcitivitySettingsView()
            case .shelf: ShelfLiveActivitySettingsView()
            case .none: BlankView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            //            }
            //            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}


struct SettingsActivityItemView: View {
    var activity: NotchNook.LiveActivity
    var selected: Bool
    var select: (_ activity: NotchNook.LiveActivity) -> ()
    @Binding var isOn: Bool
    var body: some View {
        Button {
            select(activity)
        } label: {
            HStack(spacing: 16) {
                HStack {
                    Image(systemName: activity.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .frame(24)
                        .foregroundStyle(selected ? .blue : .white)
                        .background(selected ? .white : .blue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text(activity.name)
                        .foregroundStyle(selected ? .white : .primary)
                }
                
                Toggle("", isOn: $isOn)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            .padding(8)
            .background(.blue.opacity(selected ? 0.5 : 0), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
