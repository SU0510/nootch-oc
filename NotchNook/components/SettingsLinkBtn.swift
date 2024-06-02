//
//  SettingsLinkBtn.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI

struct SettingsLinkBtn<C: View>: View {
    var url: URL?
    @ViewBuilder var content: () -> C
    @Environment(\.openURL) private var openURL
    @State private var hovering = false
    var body: some View {
        Button {
            if let url { openURL(url) }
        } label: {
            HStack {
                content()
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.secondary.opacity(hovering ? 0.15 : 0.1), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .onHover { hovering = $0 }
        }
        .buttonStyle(BrightnessDownOnClick())
    }
}
