//
//  SettingsLinkBtn.swift
//  NotchNook
//
//  Created by Igor Marcossi on 01/06/24.
//

import SwiftUI

struct SettingsLinkBtn<C: View>: View {
    var url: URL?
    var inline = true
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
            .padding(EdgeInsets(top: 10, leading: inline ? 16 : 10, bottom: 10, trailing: inline ? 16 : 10))
            .frame(maxWidth: !inline ? .infinity : nil, alignment: .leading)
            .background(.secondary.opacity(hovering ? 0.2 : 0.1), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .onHover { hovering = $0 }
        }
        .buttonStyle(BrightnessDownOnClick(cornerRadius: 24))
    }
}
