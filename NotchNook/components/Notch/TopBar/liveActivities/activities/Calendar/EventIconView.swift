//
//  EventIconView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 13/06/24.
//

import SwiftUI

struct EventIconView: View {
    var body: some View {
        Image(systemName: LiveActivity.calendar.icon)
            .font(.system(size: 13))
            .foregroundStyle(.blue)
            .frame(maxWidth: .infinity)
    }
}

