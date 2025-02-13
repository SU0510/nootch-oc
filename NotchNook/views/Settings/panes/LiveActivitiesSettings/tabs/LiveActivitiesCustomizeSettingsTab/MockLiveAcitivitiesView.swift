//
//  MockLiveAcitivitiesView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

struct MockLiveAcitivitiesView: View {
    
    var activity: LiveActivity
    
    @Environment(\.notchSize) private var notchSize
    
    var body: some View {
        ZStack(alignment: .top) {
            MockTopBar(activity: activity)
                .background {
                    NotchShape(notchSize: notchSize).offset(y: -1).fill(.black)
                }
                .clipShape(NotchShape(notchSize: notchSize).offset(y: -1))
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .top)
        .background { ActualSizeCurrentWallpaperView() }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
