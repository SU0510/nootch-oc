//
//  TopBarTabsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI

struct TopBarTabsView: View {
    var totalWidth: Grid.Point
    @Environment(\.screenID) private var screenID
    @Environment(\.openSettings) private var openSettings
    var body: some View {
        let mode = NotchNook.shared.mode[screenID]!
        let collapsed = totalWidth < .init(11)
        HStack(spacing: 2) {
            
            TopBarTabView(icon: "lamp.desk.fill", label: collapsed ? nil : "Nook", active: mode == .nook)
                .onTapGesture { withAnimation(.smooth(extraBounce: 0.25)) { NotchNook.shared.mode[screenID] = .nook } }
            
            TopBarTabView(icon: "shippingbox.fill", label: collapsed ? nil : "Box", active: mode == .shelf)
                .onTapGesture { withAnimation(.smooth(extraBounce: 0.25)) { NotchNook.shared.mode[screenID] = .shelf } }
            
            Spacer()
            
            CircleButton(icon: "gearshape.fill", iconSize: 13) {
                openSettings(nil)
            }
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
