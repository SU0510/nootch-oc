//
//  TopBarTabsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct TopBarTabsView: View {
    
    var collapsed: Bool
    @Environment(\.notchNook) private var notchNook
    @Environment(\.generalSettings) private var generalSettings
    
    var body: some View {
        HStack(spacing: 2) {
            TopBarTabView(
                icon: "lamp.desk.fill",
                label: collapsed ? nil : String(localized: "Nook"),
                active: notchNook.mode == .nook,
                round: generalSettings.preferRoundButtons
            )
            .onTapGesture { withAnimation(.smooth(extraBounce: 0.25)) { notchNook.mode = .nook } }
            .opacity(notchNook.mode == .nook ? 1 : 0.35)
            
            TopBarTabView(
                icon: LiveActivity.tray.icon,
                label: collapsed ? nil : String(localized: "Tray"),
                active: notchNook.mode == .tray,
                round: generalSettings.preferRoundButtons
            )
            .onTapGesture { withAnimation(.smooth(extraBounce: 0.25)) { notchNook.mode = .tray } }
            .opacity(notchNook.mode == .tray ? 1 : 0.35)
        }
        .padding(.trailing, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TopBarTabView: View {
    var icon: String
    var label: String?
    var active: Bool
    var round: Bool
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
        .foregroundStyle(.nonShockingWhite)
        .padding(EdgeInsets(top: 5, leading: round ? 9 : 8, bottom: 5, trailing: round ? 9 : 8))
        .background {
            if round {
                Capsule(style: .continuous).fill(.selected.opacity(active ? 1 : 0))
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.selected.opacity(active ? 1 : 0))
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}
