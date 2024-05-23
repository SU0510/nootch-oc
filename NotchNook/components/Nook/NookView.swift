//
//  NookView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/05/24.
//

import SwiftUI

struct NookView: View {
    var ns: Namespace.ID
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            MediaPlayerWidgetView(ns: ns)
            
            VDivider()
            
            ShortcutsWidgetView()
            
            VDivider()
            
            CameraWidgetView()
        }
        .defaultOpenSize(alignment: .leading)
    }
}

struct VDivider: View {
    var body: some View {
        Color.selected.opacity(0.5).frame(maxWidth: 1, maxHeight: .infinity)
    }
}
