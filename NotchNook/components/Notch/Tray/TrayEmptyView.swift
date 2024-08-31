//
//  TrayEmptyView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI

struct TrayEmptyView: View {
    var hovered: Bool
    var centered: Bool
    var body: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 6) {
            Image(systemName: LiveActivity.tray.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
            Text(LiveActivity.tray.name).fontWeight(.medium)
        }
        .multilineTextAlignment(centered ? .center : .leading)
        .foregroundStyle(hovered ? Color.blue : .nonShockingWhite)
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        .opacity(hovered ? 0.75 : 0.5)
        .transition(.scaleAndBlur)
    }
}
