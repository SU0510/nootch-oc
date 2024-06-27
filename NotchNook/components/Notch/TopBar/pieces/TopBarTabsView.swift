//
//  TopBarTabsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct TopBarTabsView: View {
    var totalWidth: NookGrid.Point
    @Environment(\.notchNook) private var notchNook
    
    var body: some View {
        let mode = notchNook.mode
        let collapsed = totalWidth < .init(9)
        HStack(spacing: 2) {
            
            TopBarTabView(icon: "lamp.desk.fill", label: collapsed ? nil : "Nook", active: notchNook.mode == .nook)
                .onTapGesture { withAnimation(.smooth(extraBounce: 0.25)) { notchNook.mode = .nook } }
            
            TopBarTabView(icon: LiveActivity.tray.icon, label: collapsed ? nil : "Tray", active: notchNook.mode == .tray)
                .onTapGesture { withAnimation(.smooth(extraBounce: 0.25)) { notchNook.mode = .tray } }
        }
        .padding(.trailing, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TopBarTabView: View {
    var icon: String
    var label: String?
    var active: Bool
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
            if let label {
                Text(label)
                    .fixedSize(horizontal: true, vertical: false)
                    .transition(.scaleAndBlur)
            }
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.white)
        .padding(EdgeInsets(top: 5, leading: 9, bottom: 5, trailing: 9))
        .background(.selected.opacity(active ? 1 : 0), in: Capsule(style: .continuous))
        .contentShape(Capsule(style: .continuous))
    }
}
