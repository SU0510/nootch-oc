//
//  WidgetsSettingsTabView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI
import Defaults

struct WidgetsSettingsTabView: View {
    @Default(.calendarWidgetSettings) private var calendarWidgetSettings
    @Default(.mediaWidgetSettings) private var mediaWidgetSettings
    @Default(.mirrorWidgetSettings) private var mirrorWidgetSettings
    @Default(.shortcutsWidgetSettings) private var shortcutsWidgetSettings
    @Default(.notesWidgetSettings) private var notesWidgetSettings
    @Default(.quickAppsWidgetSettings) private var quickAppsWidgetSettings
    @Default(.todoListWidgetSettings) private var todoListWidgetSettings
    @Default(.nookSettings) private var nookSettings
    
    var body: some View {
        MultipleSettingsPicker(
            elements: NookWidget.allCases,
            activeElements: $nookSettings.enabledWidgets,
            disableItem: { widget in
                return false
//                let otherEnabledWidgets = nookSettings.enabledWidgets.filter { $0 != widget }
//                let remainingWidth = nookSettings.size.width - otherEnabledWidgets.reduce(.zero) { $0 + $1.prefs.size.width }
//                return widget.prefs.size.width > remainingWidth
            }) { _ in
                ReorderWidgetsView(widgets: $nookSettings.enabledWidgets)
                    .padding(.horizontal, 19)
            } settings: { selectedElement in
                switch selectedElement {
                    //            case .media: MediaLiveAcitivitySettingsView()
                case .shortcuts: ShortcutsWidgetSettingsView()
                case .media: MediaWidgetSettingsView()
                case .mirror: MirrorWidgetSettingsView()
                case .calendar: CalendarWidgetSettingsView()
                case .notes: NotesWidgetSettingsView()
                default: BlankView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
    }
}

