//
//  WidgetsSettingsTabView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/05/24.
//

import SwiftUI
import Defaults

struct WidgetsSettingsTabView: View {
    @Default(.mediaWidgetSettings) private var mediaWidgetSettings
    @Default(.mirrorWidgetSettings) private var mirrorWidgetSettings
    @Default(.shortcutsWidgetSettings) private var shortcutsWidgetSettings
    @Default(.nookSettings) private var nookSettings
    @State private var selectedWidget: NookWidget?
    
    func selectWidget(_ widget: NookWidget) {
        selectedWidget = widget
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            ReorderWidgetsView(widgets: $nookSettings.enabledWidgets)
                .padding(.horizontal, 19)
            
            MultipleSettingsPicker(
                elements: NookWidget.allCases,
                activeElements: $nookSettings.enabledWidgets,
                selectedElement: $selectedWidget,
                disableItem: { widget in
                    let otherEnabledWidgets = nookSettings.enabledWidgets.filter { $0 != widget }
                    let remainingWidth = nookSettings.size.width - otherEnabledWidgets.reduce(.zero) { $0 + $1.prefs.size.width }
                    return widget.prefs.size.width > remainingWidth
                },
                settings: {
                    switch selectedWidget {
                        //            case .media: MediaLiveAcitivitySettingsView()
                    case .shortcuts: ShortcutsWidgetSettingsView()
                    case .media: MediaWidgetSettingsView()
                    case .mirror: MirrorWidgetSettingsView()
                    default: BlankView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                })
        }
    }
}

