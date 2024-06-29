//
//  GesturesSettingsView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 02/06/24.
//

import SwiftUI
import Defaults
import Settings

struct GesturesSettingsView: View {
    @Default(.gestureControlSettings) private var gestureControlSettings
    var body: some View {
        let contentMaxW: Double = 330
        Settings.Container(contentWidth: 550.0, minimumLabelWidth: 150) {
            Settings.Section {
                Text("").frame(minWidth: 100, alignment: .trailing)
            } content: {
                Toggle("Allow gestures when hovering the notch", isOn: $gestureControlSettings.allowGestures)
                
                Group {
                    Toggle(
                        "Open/close notch with vertical gestures",
                        isOn: $gestureControlSettings.controlOpenState
                    )
                    
                    Toggle(
                        "Control media with horizontal gestures",
                        isOn: $gestureControlSettings.controlMedia
                    )
                    
                    Toggle("Invert media gestures actions", isOn: $gestureControlSettings.invertMediaGestures)
                        .disabled(!gestureControlSettings.allowGestures)
                    Text("If on, a left swipe will start the next song, if off, the previous one.")
                        .optionDescription(contentMaxW)
                }
                .disabled(!gestureControlSettings.allowGestures)
            }
        }
    }
}

let GesturesSettingsViewController: () -> SettingsPane = {
    let paneView = Settings.Pane(
        identifier: .gestures,
        title: "Gestures",
        toolbarIcon: NSImage(systemSymbolName: "rectangle.and.hand.point.up.left.fill", accessibilityDescription: "Gestures settings")!
    ) {
        GesturesSettingsView()
    }
    
    return Settings.PaneHostingController(pane: paneView)
}
