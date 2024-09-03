//
//  ShortcutsWidgetView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/05/24.
//

import SwiftUI
import Defaults

struct ShortcutsWidgetView: View {
    var arrayPosition: ArrayPosition
    
    @Environment(\.openSettings) private var openSettings
    @Environment(\.nookSettings) private var nookSettings
    @Environment(\.shortcutsWidgetSettings) private var prefs
    
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
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .opacity(0.5)
                    Button("Choose Shortcuts") {
                        SettingsInnerPath.shared.tabIndex = 1
                        doAfter { openSettings(.nook) }
                    }
                }
                .padding(.horizontal, padding)
                .frame(maxWidth: .infinity)
                .scaleEffect(1)
            } else {
                Group {
                    ShortcutsRowView(
                        widgetArrayPosition: arrayPosition,
                        arrayPosition: .first,
                        shortcuts: Array(shortcuts.prefix(howManyFits)),
                        btnWidth: btnWidth.screenPoints
                    )
                    ShortcutsRowView(
                        widgetArrayPosition: arrayPosition,
                        arrayPosition: .last,
                        shortcuts: Array(shortcuts.dropFirst(howManyFits).prefix(howManyFits)),
                        btnWidth: btnWidth.screenPoints
                    )
                }
                .padding(EdgeInsets(
                    top: 0,
                    leading: arrayPosition == .first || arrayPosition == .single ? 0 : padding,
                    bottom: 0,
                    trailing:  arrayPosition == .last || arrayPosition == .single ? 0 : padding
                ))
            }
        }
        .frame(width: prefs.size.width.screenPoints, height: prefs.size.height.screenPoints, alignment: .leading)
        .onAppear {
            let oldShorts = Defaults[.shortcutsWidgetSettings].shortcutsToDisplay
            let newShorts = oldShorts.filter { ShortcutsManager.shared.shortcuts.contains($0) }
            Defaults[.shortcutsWidgetSettings].shortcutsToDisplay = newShorts
        }
    }
}

struct ShortcutsRowView: View {
    var widgetArrayPosition: ArrayPosition
    var arrayPosition: ArrayPosition
    var shortcuts: [String]
    var btnWidth: Double
    var spacingBetweenBtns: Double = 8
    
    func getRoundCornerForArrayPosition(_ innerArrPos: ArrayPosition) -> ArrayPosition? {
        if widgetArrayPosition != .middle && arrayPosition == .last {
            if innerArrPos == .single {
                return widgetArrayPosition
            }
            return innerArrPos
        }
        return nil
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(Array(shortcuts.enumerated()), id: \.element.self) { i, shortcut in
                let innerArrPos = ArrayPosition(total: shortcuts.count, i: i)
                ShortcutView(
                    roundCornerForArrayPosition: getRoundCornerForArrayPosition(innerArrPos),
                    shortcut: shortcut
                )
                .padding(EdgeInsets(
                    top: 0,
                    leading: innerArrPos == .single || innerArrPos == .first ? 0 : spacingBetweenBtns / 2,
                    bottom: 0,
                    trailing: innerArrPos == .single || innerArrPos == .last ? 0 : spacingBetweenBtns / 2
                ))
                //                    .frame(width: btnWidth)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        //        .background(.red.opacity(0.25))
    }
}

struct ShortcutView: View {
    var roundCornerForArrayPosition: ArrayPosition? = nil
    var shortcut: String
    @State private var bounce = 0
    @Environment(\.generalSettings) private var generalSettings
    var body: some View {
        let rounderPos = roundCornerForArrayPosition
        let cornerRadius: Double = 18
        let biggerCornerRadius = NotchShape.maxNotchRadius - generalSettings.contentPadding
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
                    .foregroundStyle(.nonShockingWhite)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background {
                if generalSettings.preferRoundButtons {
                    Capsule(style: .continuous).fill(.selected)
                } else {
                    UnevenRoundedRectangle(
                        topLeadingRadius: cornerRadius,
                        bottomLeadingRadius: rounderPos == .first || rounderPos == .single ? biggerCornerRadius : cornerRadius,
                        bottomTrailingRadius: rounderPos == .last || rounderPos == .single ? biggerCornerRadius : cornerRadius,
                        topTrailingRadius: cornerRadius,
                        style: .continuous
                    )
                    .fill(.selected)
                }
            }
        }
        .buttonStyle(ShrinkOnClick(minSize: 0.925))
    }
}
