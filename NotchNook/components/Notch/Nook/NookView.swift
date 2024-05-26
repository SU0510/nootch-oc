//
//  NookView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/05/24.
//

import SwiftUI

struct NookView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            MediaPlayerWidgetView()
            
            VDivider()
            
            ShortcutsWidgetView()
            
            VDivider()
            
            CameraWidgetView()
        }
        .defaultOpenSize(alignment: .leading)
        .fixedSize()
    }
}

struct VDivider: View {
    var body: some View {
        Color.selected
            .opacity(0.5)
            .frame(maxWidth: 1, maxHeight: .infinity)
            .allowsHitTesting(false)
    }
}
