//
//  NookView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/05/24.
//

import SwiftUI
import Defaults

struct NookView: View {
    @Default(.nookSettings) private var nookSettings
    @Default(.mediaWidgetSettings) private var mediaWidgetSettings
    @Default(.shortcutsWidgetSettings) private var shortcutsWidgetSettings
    @Default(.mirrorWidgetSettings) private var mirrorWidgetSettings
    var body: some View {
        let widgets = nookSettings.enabledWidgets
        HStack(alignment: .center, spacing: 0) {
            ForEach(Array(widgets.enumerated()), id: \.element) { i, widget in
                let arrPos = ArrayPosition(total: widgets.count, i: i)
                Group {
                    switch widget {
                    case .media:
                        MediaPlayerWidgetView(arrayPosition: arrPos)
                            .widgetDefaultProps(arrPos: arrPos, pref: mediaWidgetSettings, disableDivider: !nookSettings.showDividers)
                    case .shortcuts:
                        ShortcutsWidgetView(prefs: shortcutsWidgetSettings, arrayPosition: ArrayPosition(total: widgets.count, i: i))
                            .widgetDefaultProps(arrPos: arrPos, pref: shortcutsWidgetSettings, disableDivider: !nookSettings.showDividers)
                    case .mirror:
                        MirrorWidgetView(arrayPosition: arrPos)
                            .widgetDefaultProps(arrPos: arrPos, pref: mirrorWidgetSettings, disableDivider: !nookSettings.showDividers)
                    }
                }
            }
        }
        .frame(nookSettings.size.screenPtsCGSize)
        .fixedSize()
    }
}

struct VDivider: View {
    var color = Color.selected
    var body: some View {
        color
            .opacity(0.75)
            .frame(maxWidth: 1, maxHeight: .infinity)
            .allowsHitTesting(false)
    }
}

private extension View {
    func widgetDefaultProps(arrPos: ArrayPosition, pref: any WidgetPrefs, disableDivider: Bool = false) -> some View {
        self
            .frame(width: pref.size.width.screenPoints, height: pref.size.height.screenPoints, alignment: .leading)
            .overlay(alignment: .trailing) { if arrPos != .last && !disableDivider { VDivider().opacity(0.75) } }
    }
}
