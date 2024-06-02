//
//  ShortcutsWidgetView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/05/24.
//

import SwiftUI
import Defaults

struct ShortcutsWidgetView: View {
    @Default(.nookSettings) private var nookSettings
    var prefs: ShortcutsWidgetSettings
    var arrayPosition: ArrayPosition
    @Environment(\.openSettings) private var openSettings
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let shortcuts = Array(prefs.shortcutsToDisplay)
            let howManyFits = Int(floor(prefs.size.width.screenPoints / prefs.shortcutButtonWidth.screenPoints))
            let btnWidth = prefs.shortcutButtonWidth
            let padding = nookSettings.widgetsPadding
            
            if shortcuts.isEmpty {
                VStack {
                    Image(systemName: "sparkles").font(.system(size: 24))
                        .opacity(0.5)
                    Text("Choose your shortcuts in settings.")
                        .multilineTextAlignment(.center)
                        .opacity(0.5)
                    Button("Choose Shortcuts") {
                        SettingsInnerPath.shared.tabIndex = 1
                        doThisAfter(0) { openSettings(.nook) }
                    }
                }
                .padding(.horizontal, padding)
                .frame(maxWidth: .infinity)
                .scaleEffect(1)
            } else {
                ShortcutsRowView(
                    shortcuts: Array(shortcuts.prefix(howManyFits)),
                    btnWidth: btnWidth.screenPoints,
                    arrayPosition: arrayPosition,
                    padding: padding
                )
                
                ShortcutsRowView(
                    shortcuts: Array(shortcuts.dropFirst(howManyFits).prefix(howManyFits)),
                    btnWidth: btnWidth.screenPoints,
                    arrayPosition: arrayPosition,
                    padding: padding
                )
            }
        }
        .frame(width: prefs.size.width.screenPoints, height: prefs.size.height.screenPoints, alignment: .leading)
    }
}

struct ShortcutsRowView: View {
    var shortcuts: [String]
    var btnWidth: Double
    var arrayPosition: ArrayPosition
    var padding: Double
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
                ForEach(Array(shortcuts.enumerated()), id: \.element.self) { i, shortcut in
                    let innerArrPos = ArrayPosition(total: shortcuts.count, i: i)
                    ShortcutView(shortcut: shortcut)
                        .padding(EdgeInsets(
                            top: 0,
                            leading:
                                innerArrPos == .middle || (innerArrPos == .last)
                            ? 4
                            : arrayPosition == .first && innerArrPos == .first ? 0 : padding,
                            bottom: 0,
                            trailing:
                                innerArrPos == .middle || (innerArrPos == .first)
                            ? 4
                            : innerArrPos == .last && arrayPosition == .last ? 0 : padding
                        ))
                        .frame(width: btnWidth)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
//        .background(.red.opacity(0.25))
    }
}

struct ShortcutView: View {
//    var shortcut: Shortcut
    var shortcut: String
    @State private var bounce = 0
    var body: some View {
        Button {
            bounce += 1
//            ShortcutsManager.shared.runShortcut(named: shortcut.name)
            ShortcutsManager.shared.runShortcut(named: shortcut)
        } label: {
            HStack(spacing: 4) {
//                Image(systemName: shortcut.icon)
                Image(systemName: "sparkles")
                    .symbolEffect(.bounce, value: bounce)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.yellow)
//                Text(shortcut.name)
                Text(shortcut)
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
