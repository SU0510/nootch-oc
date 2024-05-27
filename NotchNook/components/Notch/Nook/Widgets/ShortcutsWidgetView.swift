//
//  ShortcutsWidgetView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/05/24.
//

import SwiftUI

struct ShortcutsWidgetView: View {
    var body: some View {
        let shortcuts = ShortcutsManager.shared.shortcuts
        VStack {
            
            HStack {
                ForEach(shortcuts.prefix(1)) { shortcut in
                    ShortcutView(shortcut: shortcut)
                }
            }
            
            HStack {
                ForEach([shortcuts[2]]) { shortcut in
                    ShortcutView(shortcut: shortcut)
                }
            }
        }
    }
}

struct ShortcutView: View {
    var shortcut: Shortcut
    @State private var bounce = 0
    var body: some View {
        Button {
            bounce += 1
            ShortcutsManager.shared.runShortcut(named: shortcut.name)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: shortcut.icon)
                    .symbolEffect(.bounce, value: bounce)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.yellow)
                Text(shortcut.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(.selected, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(ShrinkOnClick(minSize: 0.925))
    }
}
