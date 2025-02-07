//
//  LiveActivityIconView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct LiveActivityIconView: View {
    
    var liveActivity: LiveActivity
    
    var body: some View {
        Image(systemName: liveActivity.icon)
            .font(.system(size: 13))
            .foregroundStyle(.nonShockingWhite)
            .frame(maxWidth: .infinity)
    }
}

