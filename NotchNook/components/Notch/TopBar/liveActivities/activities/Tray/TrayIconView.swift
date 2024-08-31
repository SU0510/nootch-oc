//
//  TrayIconView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct TrayIconView: View {
    var body: some View {
        Image(systemName: LiveActivity.tray.icon)
            .font(.system(size: 13))
            .foregroundStyle(.nonShockingWhite)
            .frame(maxWidth: .infinity)
    }
}

