//
//  TrayFilesCountView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct TrayFilesCountView: View {
    @Environment(\.tray) private var tray
    var body: some View {
        HStack(spacing: 2) {
            Text("\(tray.files.count)")
            Image(systemName: ActiveLiveActivitiesManager.shared.activeLiveActivities.count > 1 ? LiveActivity.tray.icon : "doc.fill")
                .contentTransition(.symbolEffect)
        }
        .frame(maxWidth: .infinity)
        .font(.system(size: 13))
        .foregroundStyle(.nonShockingWhite)
    }
}
