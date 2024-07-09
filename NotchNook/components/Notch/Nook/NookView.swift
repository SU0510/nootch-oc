//
//  NookView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/05/24.
//

import SwiftUI
import Defaults

struct NookView: View {
    @Environment(\.nookSettings) private var nookSettings
    
    var body: some View {
        let widgets = nookSettings.enabledWidgets
        HStack(alignment: .center, spacing: 0) {
            ForEach(Array(widgets.enumerated()), id: \.element) { i, widget in
                let arrPos = ArrayPosition(total: widgets.count, i: i)
                Group {
                    switch widget {
                        case .media:
                            MediaPlayerWidgetView(arrayPosition: arrPos)
                        case .shortcuts:
                            ShortcutsWidgetView(arrayPosition: ArrayPosition(total: widgets.count, i: i))
                        case .mirror:
                            MirrorWidgetView(arrayPosition: arrPos)
                        case .calendar:
                            CalendarWidgetView()
                        case .notes: 
                            NotesWidgetView(arrayPosition: arrPos, internalPadding: nookSettings.widgetsPadding)
                        default: EmptyView()
                    }
                }
                .widgetDefaultProps(arrPos: arrPos, pref: widget.prefs, disableDivider: !nookSettings.showDividers)
            }
        }
        .animation(.smooth, value: nookSettings.enabledWidgets)
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
            .frame(pref.size.screenPtsCGSize, .leading)
            .overlay(alignment: .trailing) { if arrPos != .last && arrPos != .single && !disableDivider { VDivider().opacity(0.75) } }
    }
}
